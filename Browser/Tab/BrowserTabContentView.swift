//
//  BrowserTabContentView.swift
//  Browser
//
//  Created by Amer Hukić on 13. 9. 2021..
//

import UIKit
import WebKit
import SnapKit

class BrowserTabContentView: UIView {
  let webView: WKWebView = {
    let webView = WKWebView()
    webView.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 18_7 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/26.5 Mobile/15E148 Safari/604.1"
    webView.backgroundColor = .black
    webView.isOpaque = false
    return webView
  }()
  let emptyStateView = BrowserTabEmptyStateView()
  let statusBarBackgroundView = StatusBarBackgroundView()
  var statusBarBackgroundViewHeightConstraint: Constraint?

  override init(frame: CGRect) {
    super.init(frame: frame)
    setupView()
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func layoutSubviews() {
    super.layoutSubviews()
    let statusBarHeight = window?.windowScene?.statusBarManager?.statusBarFrame.height ?? 0
    statusBarBackgroundViewHeightConstraint?.update(offset: statusBarHeight)
  }
}

// MARK: Helper methods
private extension BrowserTabContentView {
  func setupView() {
    backgroundColor = .black
    layer.masksToBounds = false
    setupShadow()
    setupWebView()
    setupEmptyStateView()
    setupStatusBarBackgroundView()
  }
  
  func setupShadow() {
    // A view-wide light shadow creates a visible horizontal seam at the top of
    // webpages. Safari's content itself should extend edge-to-edge instead.
    layer.masksToBounds = false
    layer.shadowOpacity = 0
    layer.shadowRadius = 0
  }
  
  func setupWebView() {
    webView.allowsBackForwardNavigationGestures = true
    webView.scrollView.automaticallyAdjustsScrollIndicatorInsets = false
    webView.scrollView.contentInsetAdjustmentBehavior = .never
    webView.scrollView.contentInset = .zero
    webView.scrollView.layer.masksToBounds = false
    addSubview(webView)
    webView.snp.makeConstraints {
      // Extend page content behind the status bar, like Safari's edge-to-edge
      // layout. Pinning to safeAreaLayoutGuide leaves an unwanted strip/seam.
      $0.edges.equalToSuperview()
    }
  }
  
  func setupStatusBarBackgroundView() {
    // Keep a dark reference color for preferredStatusBarStyle while the view
    // itself is hidden so the webpage renders under the status bar edge-to-edge.
    statusBarBackgroundView.backgroundColor = UIColor(red: 0.025, green: 0.025, blue: 0.03, alpha: 1)
    statusBarBackgroundView.isHidden = true
    statusBarBackgroundView.isUserInteractionEnabled = false
    addSubview(statusBarBackgroundView)
    statusBarBackgroundView.snp.makeConstraints {
      $0.top.leading.trailing.equalToSuperview()
      statusBarBackgroundViewHeightConstraint = $0.height.equalTo(0).constraint
    }
  }
  
  func setupEmptyStateView() {
    emptyStateView.alpha = 0
    addSubview(emptyStateView)
    emptyStateView.snp.makeConstraints {
      $0.edges.equalToSuperview()
    }
  }
}
