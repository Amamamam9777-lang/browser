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
    private let aAButton = UIButton(type: .custom)
    private let pageMenuPuzzleImageView = UIImageView()
    private let pageMenuTopLine = UIView()
    private let pageMenuBottomLine = UIView()
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
      let height: CGFloat
      switch activityState {
      case .editing:
        width = 5
        height = 22
      case .inactive:
        width = 30
        height = 32
      }
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
    // Safari-style page menu mark: a puzzle piece above two short menu lines.
    // Keep the symbol and lines as native views so they stay crisp at every scale.
    let iconColor = UIColor { traits in
      traits.userInterfaceStyle == .dark
        ? UIColor(white: 0.76, alpha: 1)
        : UIColor(white: 0.30, alpha: 1)
    }

    pageMenuPuzzleImageView.image = (
      UIImage(systemName: "puzzlepiece.extension.fill")
        ?? UIImage(systemName: "puzzlepiece.fill")
    )?.withRenderingMode(.alwaysTemplate)
    pageMenuPuzzleImageView.tintColor = iconColor
    pageMenuPuzzleImageView.contentMode = .scaleAspectFit
    pageMenuPuzzleImageView.translatesAutoresizingMaskIntoConstraints = false

    [pageMenuTopLine, pageMenuBottomLine].forEach { line in
      line.backgroundColor = iconColor
      line.layer.cornerRadius = 1.5
      line.translatesAutoresizingMaskIntoConstraints = false
      aAButton.addSubview(line)
    }

    aAButton.addSubview(pageMenuPuzzleImageView)
    NSLayoutConstraint.activate([
      pageMenuPuzzleImageView.topAnchor.constraint(equalTo: aAButton.topAnchor),
      pageMenuPuzzleImageView.centerXAnchor.constraint(equalTo: aAButton.centerXAnchor),
      pageMenuPuzzleImageView.widthAnchor.constraint(equalToConstant: 19),
      pageMenuPuzzleImageView.heightAnchor.constraint(equalToConstant: 19),

      pageMenuTopLine.topAnchor.constraint(equalTo: pageMenuPuzzleImageView.bottomAnchor, constant: 1),
      pageMenuTopLine.leadingAnchor.constraint(equalTo: aAButton.leadingAnchor, constant: 3),
      pageMenuTopLine.trailingAnchor.constraint(equalTo: aAButton.trailingAnchor, constant: -3),
      pageMenuTopLine.heightAnchor.constraint(equalToConstant: 3),

      pageMenuBottomLine.topAnchor.constraint(equalTo: pageMenuTopLine.bottomAnchor, constant: 3),
      pageMenuBottomLine.leadingAnchor.constraint(equalTo: aAButton.leadingAnchor, constant: 8),
      pageMenuBottomLine.trailingAnchor.constraint(equalTo: aAButton.trailingAnchor, constant: -8),
      pageMenuBottomLine.heightAnchor.constraint(equalToConstant: 3),
      pageMenuBottomLine.bottomAnchor.constraint(lessThanOrEqualTo: aAButton.bottomAnchor)
    ])

    aAButton.tintColor = iconColor
    aAButton.adjustsImageWhenHighlighted = false
    aAButton.accessibilityLabel = "Page settings"
    aAButton.accessibilityHint = "Open page settings"
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
