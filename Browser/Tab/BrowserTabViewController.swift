//
//  BrowserTabViewController.swift
//  Browser
//
//  Created by Amer Hukić on 10. 9. 2021..
//

import UIKit
import WebKit

protocol BrowserTabViewControllerDelegate: AnyObject {
  func tabViewController(_ tabViewController: BrowserTabViewController, didStartLoadingURL url: URL)
  func tabViewController(_ tabViewController: BrowserTabViewController, didChangeLoadingProgressTo progress: Float)
  func tabViewControllerDidScroll(yOffsetChange: CGFloat)
  func tabViewControllerDidEndDragging()
}

class BrowserTabViewController: UIViewController {
  private let contentView = BrowserTabContentView()
  private var isScrolling = false
  private var startYOffset = CGFloat(0)
  private var loadingProgressObservation: NSKeyValueObservation?
  var hasLoadedUrl = false
  var currentURL: URL? { contentView.webView.url }
  func goBackIfPossible() { if contentView.webView.canGoBack { contentView.webView.goBack() } }
  func goForwardIfPossible() { if contentView.webView.canGoForward { contentView.webView.goForward() } }
  func reloadWebsite() { contentView.webView.reload() }
  weak var delegate: BrowserTabViewControllerDelegate?
  
  override var preferredStatusBarStyle: UIStatusBarStyle {
    let isBackgroundColorDark = contentView.statusBarBackgroundView.backgroundColor?.isDark ?? false
    return isBackgroundColorDark ? .lightContent : .darkContent
  }
  
  override func loadView() {
    view = contentView
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    view.overrideUserInterfaceStyle = .dark
    contentView.emptyStateView.onOpenURL = { [weak self] url in
      self?.loadWebsite(from: url)
    }
    setupWebView()
  }

  /// Captures a lightweight thumbnail for the tab overview.
  /// Requests are queued by the overview controller, rather than fired for all
  /// WKWebViews simultaneously. Avoid snapshotting a page during navigation,
  /// when WebKit is most likely to be rebuilding its backing surface.
  func captureTabSnapshot(completion: @escaping (UIImage?) -> Void) {
    if hasLoadedUrl {
      let webView = contentView.webView
      guard webView.bounds.width > 1,
            webView.bounds.height > 1,
            !webView.isLoading else {
        DispatchQueue.main.async { completion(nil) }
        return
      }
      let configuration = WKSnapshotConfiguration()
      configuration.rect = CGRect(origin: .zero, size: webView.bounds.size)
      webView.takeSnapshot(with: configuration) { image, _ in
        DispatchQueue.main.async {
          guard let image else { completion(nil); return }
          completion(Self.makeTabThumbnail(from: image))
        }
      }
      return
    }

    // The native start page contains only UIKit views; render this surface
    // alone, rather than asking UIKit to draw the WKWebView underneath it.
    DispatchQueue.main.async { [weak self] in
      guard let self else { completion(nil); return }
      let startPage = self.contentView.emptyStateView
      startPage.layoutIfNeeded()
      let size = startPage.bounds.size
      guard size.width > 1, size.height > 1 else { completion(nil); return }
      let renderer = UIGraphicsImageRenderer(size: size)
      let image = renderer.image { context in
        startPage.layer.render(in: context.cgContext)
      }
      completion(Self.makeTabThumbnail(from: image))
    }
  }

  private static func makeTabThumbnail(from image: UIImage) -> UIImage {
    // Tab cards only need a small preview. Rendering at 1x and limiting the
    // width keeps many open tabs from retaining full-resolution screenshots.
    let maxWidth: CGFloat = 400
    let scale = min(1, maxWidth / max(image.size.width, 1))
    let size = CGSize(width: max(1, image.size.width * scale),
                      height: max(1, image.size.height * scale))
    let format = UIGraphicsImageRendererFormat()
    format.scale = 1
    format.opaque = true
    return UIGraphicsImageRenderer(size: size, format: format).image { _ in
      image.draw(in: CGRect(origin: .zero, size: size))
    }
  }
  
  override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
    guard isViewLoaded else { return }
    switch keyPath {
    case #keyPath(WKWebView.url):
      // WKWebView may publish nil while a blank tab is being prepared.
      // Do not force-unwrap this KVO value.
      if let url = contentView.webView.url {
        delegate?.tabViewController(self, didStartLoadingURL: url)
      }
    case #keyPath(WKWebView.estimatedProgress):
      delegate?.tabViewController(self, didChangeLoadingProgressTo: Float(contentView.webView.estimatedProgress))
    case #keyPath(WKWebView.themeColor):
      updateStatusBarColor()
    case #keyPath(WKWebView.underPageBackgroundColor):
      updateStatusBarColor()
    default:
      super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
    }
  }
  
  func loadWebsite(from url: URL) {
    contentView.webView.load(URLRequest(url: url))
    hasLoadedUrl = true
    hideEmptyStateIfNeeded()
  }
  
  func showEmptyState() {
    UIView.animate(withDuration: 0.2) {
      self.contentView.emptyStateView.alpha = 1
    }
  }
  
  func hideEmptyStateIfNeeded() {
    guard hasLoadedUrl else { return }
    UIView.animate(withDuration: 0.2) {
      self.contentView.emptyStateView.alpha = 0
    }
  }
}

// MARK: Helper methods
private extension BrowserTabViewController {
  func setupWebView() {
    contentView.webView.scrollView.panGestureRecognizer.addTarget(self, action: #selector(handlePan(_:)))
    contentView.webView.navigationDelegate = self
    contentView.webView.addObserver(self, forKeyPath: #keyPath(WKWebView.estimatedProgress), options: .new, context: nil)
    contentView.webView.addObserver(self, forKeyPath: #keyPath(WKWebView.url), options: .new, context: nil)
    contentView.webView.addObserver(self, forKeyPath: #keyPath(WKWebView.themeColor), options: .new, context: nil)
    contentView.webView.addObserver(self, forKeyPath: #keyPath(WKWebView.underPageBackgroundColor), options: .new, context: nil)
  }
  
  func updateStatusBarColor() {
    // While a new tab's native Start Page is visible, never inherit WebKit's
    // default white under-page color. Use the live website color only after load.
    let color: UIColor
    if hasLoadedUrl {
      color = (contentView.webView.themeColor ?? contentView.webView.underPageBackgroundColor ?? .black).withAlphaComponent(1)
    } else {
      color = UIColor(red: 0.025, green: 0.025, blue: 0.03, alpha: 1)
    }
    contentView.statusBarBackgroundView.backgroundColor = color
    setNeedsStatusBarAppearanceUpdate()
  }
}

// MARK: Action methods
private extension BrowserTabViewController {
  @objc func handlePan(_ panGestureRecognizer: UIPanGestureRecognizer) {
    let yOffset = contentView.webView.scrollView.contentOffset.y
    switch panGestureRecognizer.state {
    case .began:
      startYOffset = yOffset
    case .changed:
      delegate?.tabViewControllerDidScroll(yOffsetChange: startYOffset - yOffset)
    case .failed, .ended, .cancelled:
      delegate?.tabViewControllerDidEndDragging()
    default:
      break
    }
  }
}

// MARK: WKNavigationDelegate
extension BrowserTabViewController: WKNavigationDelegate {
  func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
    if navigationAction.navigationType == .linkActivated {
      // handle redirects
      guard let url = navigationAction.request.url else { return }
      webView.load(URLRequest(url: url))
    }
    decisionHandler(.allow)
  }
}
