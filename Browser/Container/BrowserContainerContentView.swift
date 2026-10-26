//
//  BrowserContainerContentView.swift
//  Browser
//
//  Created by Amer Hukić on 10. 9. 2021..
//

import UIKit
import SnapKit

class BrowserContainerContentView: UIView {
  let cancelButton = UIButton(type: .system)
  let tabsScrollView = UIScrollView()
  let tabsStackView = UIStackView()
  let addressBarsScrollView = UIScrollView()
  let addressBarsStackView = UIStackView()
  let addressBarKeyboardBackgroundView = UIView()
  let toolbar = BrowserToolbar()
  
  var addressBarsScrollViewBottomConstraint: Constraint?
  var addressBarKeyboardBackgroundViewBottomConstraint: Constraint?
  var toolbarBottomConstraint: Constraint?
  
  // Address bar animation constants
  let tabsStackViewSpacing = CGFloat(24)
  let addressBarWidthOffset = CGFloat(0)
  let addressBarContainerHidingWidthOffset = CGFloat(-200)
  let addressBarsStackViewSidePadding = CGFloat(0)
  let addressBarsStackViewSpacing = CGFloat(12)
  let addressBarsHidingCenterOffset = CGFloat(30)
  
  // Toolbar collapsing and expanding animation constants
  let addressBarsScrollViewExpandingHalfwayBottomOffset = CGFloat(0)
  let addressBarsScrollViewExpandingFullyBottomOffset = CGFloat(0)
  let addressBarsScrollViewCollapsingHalfwayBottomOffset = CGFloat(0)
  let addressBarsScrollViewCollapsingFullyBottomOffset = CGFloat(0)
  let toolbarCollapsingHalfwayBottomOffset = CGFloat(0)
  let toolbarCollapsingFullyBottomOffset = CGFloat(0)
  let toolbarExpandingHalfwayBottomOffset = CGFloat(0)
  let toolbarExpandingFullyBottomOffset = CGFloat(0)

  var addressBarPageWidth: CGFloat {
    max(addressBarsScrollView.bounds.width, frame.width - 148) + addressBarsStackViewSpacing
  }
  
  var addressBars: [BrowserAddressBar] {
    addressBarsStackView.arrangedSubviews as? [BrowserAddressBar] ?? []
  }
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    setupView()
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

// MARK: Helper methods
private extension BrowserContainerContentView {
  func setupView() {
    backgroundColor = UIColor(red: 0.025, green: 0.025, blue: 0.03, alpha: 1)
    setupTabsScrollView()
    setupTabsStackView()
    setupToolbar()
    setupAddressBarsScrollView()
    setupAddressBarsStackView()
    setupAddressBarKeyboardBackgroundView()
    setupCancelButton()
  }
  
  func setupTabsScrollView() {
    tabsScrollView.showsHorizontalScrollIndicator = false
    tabsScrollView.showsVerticalScrollIndicator = false
    tabsScrollView.isScrollEnabled = false
    // turn off masks to bounds to allow webview content to show under the toolbar
    tabsScrollView.layer.masksToBounds = false
    addSubview(tabsScrollView)
    tabsScrollView.snp.makeConstraints {
      $0.top.leading.trailing.equalToSuperview()
    }
  }
  
  func setupTabsStackView() {
    tabsStackView.axis = .horizontal
    tabsStackView.alignment = .fill
    tabsStackView.distribution = .fillEqually
    tabsStackView.spacing = tabsStackViewSpacing
    tabsScrollView.addSubview(tabsStackView)
    tabsStackView.snp.makeConstraints {
      $0.edges.equalToSuperview()
      $0.height.equalToSuperview()
    }
  }
  
  func setupToolbar() {
    addSubview(toolbar)
    toolbar.snp.makeConstraints {
      $0.top.equalTo(tabsScrollView.snp.bottom)
      $0.centerX.equalToSuperview()
      $0.leading.trailing.equalToSuperview().inset(12)
      toolbarBottomConstraint = $0.bottom.equalTo(safeAreaLayoutGuide.snp.bottom).offset(-8).constraint
      $0.height.equalTo(56)
    }
  }
  
  func setupAddressBarsScrollView() {
    addressBarsScrollView.clipsToBounds = false
    addressBarsScrollView.showsHorizontalScrollIndicator = false
    addressBarsScrollView.showsVerticalScrollIndicator = false
    addressBarsScrollView.decelerationRate = .fast
    addSubview(addressBarsScrollView)
    addressBarsScrollView.snp.makeConstraints {
      // Address field is its own glass capsule, aligned with the round glass buttons.
      $0.leading.equalTo(toolbar.snp.leading).offset(62)
      $0.trailing.equalTo(toolbar.snp.trailing).inset(62)
      addressBarsScrollViewBottomConstraint = $0.bottom.equalTo(toolbar.snp.bottom).constraint
      $0.height.equalTo(56)
    }
  }
  
  func setupAddressBarsStackView() {
    addressBarsStackView.clipsToBounds = false
    addressBarsStackView.axis = .horizontal
    addressBarsStackView.alignment = .fill
    addressBarsStackView.distribution = .fill
    addressBarsStackView.spacing = addressBarsStackViewSpacing
    addressBarsScrollView.addSubview(addressBarsStackView)
    addressBarsStackView.snp.makeConstraints {
      $0.edges.equalToSuperview()
      $0.height.equalToSuperview()
    }
  }
  
  func setupAddressBarKeyboardBackgroundView() {
    // This backing surface is needed only while the keyboard is visible. Leaving
    // it visible at launch creates the unwanted light strip behind the toolbar.
    addressBarKeyboardBackgroundView.backgroundColor = .keyboardGray
    addressBarKeyboardBackgroundView.isHidden = true
    insertSubview(addressBarKeyboardBackgroundView, belowSubview: toolbar)
    addressBarKeyboardBackgroundView.snp.makeConstraints {
      addressBarKeyboardBackgroundViewBottomConstraint = $0.bottom.equalTo(safeAreaLayoutGuide).constraint
      $0.leading.trailing.equalToSuperview()
      $0.height.equalTo(72)
    }
  }
  
  func setupCancelButton() {
    cancelButton.titleLabel?.font = UIFont.systemFont(ofSize: 18)
    cancelButton.setTitle("Cancel", for: .normal)
    cancelButton.alpha = 0
    addSubview(cancelButton)
    cancelButton.snp.makeConstraints {
      $0.top.equalTo(safeAreaLayoutGuide).offset(8)
      $0.trailing.equalToSuperview().inset(24)
    }
  }
}
