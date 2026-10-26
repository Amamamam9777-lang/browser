//
//  BrowserAddressBar+TextField.swift
//  Browser
//
//  Created by Amer Hukić on 11. 9. 2021..
//

import UIKit

extension BrowserAddressBar.TextField {
  enum State {
    case editing
    case inactive
  }
}

extension BrowserAddressBar {
  class TextField: UITextField {
    private let paddingView = UIView()
    private let magnifyingGlassImageView = UIImageView()
    private let aAButton = UIButton(type: .system)
    var onPageMenu: (() -> Void)?
    
    var activityState = State.inactive {
      didSet {
        switch activityState {
        case .editing:
          placeholder = nil
          leftView = paddingView
          rightView = nil
          selectAll(nil)
          textColor = UIColor { traits in traits.userInterfaceStyle == .dark ? .white : .black }
        case .inactive:
          showDefaultPlaceholder()
          leftView = hasText ? aAButton : magnifyingGlassImageView
          // Safari's reload icon is intentionally omitted from this clone's
          // address field. It used to sit on top of the domain label.
          rightView = nil
          textColor = .clear
        }
      }
    }
    
    override init(frame: CGRect) {
      super.init(frame: frame)
      setupView()
    }
    
    required init?(coder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
    }
    
    override func leftViewRect(forBounds bounds: CGRect) -> CGRect {
      let width: CGFloat
      switch activityState {
      case .editing:
        width = 5
      case .inactive:
        width = 30
      }
      let height = CGFloat(22)
      let y = (bounds.height - height) / 2
      return CGRect(x: 10, y: y, width: width, height: height)
    }

    override func rightViewRect(forBounds bounds: CGRect) -> CGRect {
      let width = CGFloat(35)
      let height = CGFloat(22)
      let y = (bounds.height - height) / 2
      return CGRect(x: bounds.width - width - 5, y: y, width: width, height: height)
    }

    override func clearButtonRect(forBounds bounds: CGRect) -> CGRect {
      var rect = super.clearButtonRect(forBounds: bounds)
      rect.origin.x -= 15
      rect.size.width = 30
      return rect
    }
  }
}

// MARK: Helper methods
private extension BrowserAddressBar.TextField {
  func setupView() {
    layer.cornerRadius = 22
    backgroundColor = .clear
    clearButtonMode = .whileEditing
    returnKeyType = .go
    leftViewMode = .always
    rightViewMode = .never
    autocorrectionType = .no
    autocapitalizationType = .none
    keyboardType = .webSearch
    enablesReturnKeyAutomatically = true
    clipsToBounds = true
    setupMagnifyingGlassImage()
    setupAaButton()
    activityState = .inactive
  }
  
  func setupMagnifyingGlassImage() {
    magnifyingGlassImageView.image = UIImage(systemName: "magnifyingglass")?.withRenderingMode(.alwaysTemplate)
    magnifyingGlassImageView.tintColor = .textFieldGray
    magnifyingGlassImageView.contentMode = .scaleAspectFit
  }
  
  func setupAaButton() {
    aAButton.setTitle("aA", for: .normal)
    aAButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
    aAButton.setTitleColor(UIColor { traits in traits.userInterfaceStyle == .dark ? .white : .black }, for: .normal)
    aAButton.accessibilityLabel = "Page settings"
    aAButton.addTarget(self, action: #selector(pageMenuTapped), for: .touchUpInside)
  }
  
  func showDefaultPlaceholder() {
    let attributes: [NSAttributedString.Key: Any] = [.foregroundColor: UIColor.textFieldGray]
    attributedPlaceholder = NSAttributedString(string: "Search or enter website", attributes: attributes)
  }
}

private extension BrowserAddressBar.TextField {
  @objc func pageMenuTapped() { onPageMenu?() }
}
