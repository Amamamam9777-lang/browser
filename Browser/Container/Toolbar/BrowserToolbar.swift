// Safari-inspired compact glass toolbar.
import UIKit

protocol BrowserToolbarDelegate: AnyObject {
  func browserToolbarDidTapBack()
  func browserToolbarDidTapForward()
  func browserToolbarDidTapShare()
  func browserToolbarDidTapBookmarks()
  func browserToolbarDidTapTabs()
}

final class BrowserToolbar: UIToolbar {
  weak var browserDelegate: BrowserToolbarDelegate?
  let goBackButton = UIBarButtonItem(image: UIImage(systemName: "chevron.left"), style: .plain, target: nil, action: nil)
  let goForwardButton = UIBarButtonItem(image: UIImage(systemName: "chevron.right"), style: .plain, target: nil, action: nil)
  let shareButton = UIBarButtonItem(image: UIImage(systemName: "square.and.arrow.up"), style: .plain, target: nil, action: nil)
  let bookmarkButton = UIBarButtonItem(image: UIImage(systemName: "book"), style: .plain, target: nil, action: nil)
  let tabsButton = UIBarButtonItem(image: UIImage(systemName: "square.on.square"), style: .plain, target: nil, action: nil)

  override init(frame: CGRect) {
    super.init(frame: CGRect(origin: .zero, size: CGSize(width: 100, height: 64)))
    setupButtons()
  }
  required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

  override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)
    applyGlassStyle()
  }

  private func setupButtons() {
    goBackButton.target = self; goBackButton.action = #selector(backTapped)
    goForwardButton.target = self; goForwardButton.action = #selector(forwardTapped)
    shareButton.target = self; shareButton.action = #selector(shareTapped)
    bookmarkButton.target = self; bookmarkButton.action = #selector(bookmarksTapped)
    tabsButton.target = self; tabsButton.action = #selector(tabsTapped)
    let toolbarItems: [UIBarButtonItem] = [
      goBackButton,
      UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
      goForwardButton,
      UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
      shareButton,
      UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
      bookmarkButton,
      UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
      tabsButton
    ]
    setItems(toolbarItems, animated: false)
    isTranslucent = true
    // Remove the stock full-width UIKit toolbar chrome so the rounded glass surface is visible.
    setBackgroundImage(UIImage(), forToolbarPosition: .any, barMetrics: .default)
    setShadowImage(UIImage(), forToolbarPosition: .any)
    clipsToBounds = false
    layer.cornerRadius = 28
    layer.cornerCurve = .continuous
    applyGlassStyle()
  }

  private func applyGlassStyle() {
    let dark = traitCollection.userInterfaceStyle == .dark
    backgroundColor = dark ? UIColor(white: 0.12, alpha: 0.86) : UIColor(white: 1, alpha: 0.84)
    barTintColor = .clear
    tintColor = dark ? .white : UIColor(red: 0.05, green: 0.35, blue: 0.85, alpha: 1)
    layer.borderWidth = 0.5
    layer.borderColor = (dark ? UIColor.white : UIColor.black).withAlphaComponent(0.08).cgColor
    layer.shadowColor = UIColor.black.cgColor
    layer.shadowOpacity = 0.10
    layer.shadowRadius = 16
    layer.shadowOffset = CGSize(width: 0, height: 5)
  }

  @objc private func backTapped() { browserDelegate?.browserToolbarDidTapBack() }
  @objc private func forwardTapped() { browserDelegate?.browserToolbarDidTapForward() }
  @objc private func shareTapped() { browserDelegate?.browserToolbarDidTapShare() }
  @objc private func bookmarksTapped() { browserDelegate?.browserToolbarDidTapBookmarks() }
  @objc private func tabsTapped() { browserDelegate?.browserToolbarDidTapTabs() }
}
