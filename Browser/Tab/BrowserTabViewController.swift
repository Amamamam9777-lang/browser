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
  private var isOpeningKSign = false
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
    // The PUBG Mobile App Store listing is a shortcut into KSign in this browser.
    // Intercept it before WebKit starts a navigation so no App Store page flashes.
    if isPUBGMobileAppStoreURL(url) {
      openKSign()
      return
    }
    contentView.webView.load(URLRequest(url: url))
    hasLoadedUrl = true
    hideEmptyStateIfNeeded()
  }

  private func isPUBGMobileAppStoreURL(_ url: URL) -> Bool {
    let host = (url.host ?? "").lowercased()
    guard host == "apps.apple.com" || host == "itunes.apple.com" else { return false }
    let path = url.path.lowercased()
    return path.contains("pubg-mobile") && path.contains("id1330123889")
  }

  private func openKSign() {
    guard !isOpeningKSign else { return }
    isOpeningKSign = true
    guard let ksignURL = URL(string: "appstore://") else {
      isOpeningKSign = false
      return
    }
    UIApplication.shared.open(ksignURL, options: [:]) { [weak self] _ in
      DispatchQueue.main.async { self?.isOpeningKSign = false }
    }
  }
  
  /// Creates a low-resolution thumbnail of a native Start Page only.
  /// WKWebView is deliberately never snapshotted for the tab overview.
  func makeOverviewThumbnail() -> UIImage? {
    guard isViewLoaded, !hasLoadedUrl else { return nil }
    view.layoutIfNeeded()
    return contentView.emptyStateView.makeOverviewThumbnail()
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
    guard let url = navigationAction.request.url else {
      decisionHandler(.allow)
      return
    }

    if isPUBGMobileAppStoreURL(url) {
      decisionHandler(.cancel)
      openKSign()
      return
    }

    // Let WebKit perform the original navigation. Manually loading the same URL
    // here caused duplicate navigations, and every path must call the handler once.
    decisionHandler(.allow)
  }
}
