// Compact custom glass toolbar. Uses a custom UIView rather than UIToolbar so UIKit's
// full-width toolbar background/shadow cannot reappear behind the floating capsule.
import UIKit

protocol BrowserToolbarDelegate: AnyObject {
  func browserToolbarDidTapBack()
  func browserToolbarDidTapForward()
  func browserToolbarDidTapShare()
  func browserToolbarDidTapBookmarks()
  func browserToolbarDidTapTabs()
}

final class BrowserToolbar: UIView {
  weak var browserDelegate: BrowserToolbarDelegate?

  private let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .systemThinMaterial))
  private let buttonStack = UIStackView()
  private var iconButtons: [UIButton] = []

  override init(frame: CGRect) {
    super.init(frame: frame)
    setupView()
  }

  required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

  override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)
    updateStyle()
  }

  private func setupView() {
    backgroundColor = .clear
    clipsToBounds = false
    layer.cornerRadius = 27
    layer.cornerCurve = .continuous

    blurView.clipsToBounds = true
    blurView.layer.cornerRadius = 27
    blurView.layer.cornerCurve = .continuous
    addSubview(blurView)
    blurView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      blurView.leadingAnchor.constraint(equalTo: leadingAnchor),
      blurView.trailingAnchor.constraint(equalTo: trailingAnchor),
      blurView.topAnchor.constraint(equalTo: topAnchor),
      blurView.bottomAnchor.constraint(equalTo: bottomAnchor)
    ])

    buttonStack.axis = .horizontal
    buttonStack.alignment = .center
    buttonStack.distribution = .fillEqually
    buttonStack.spacing = 0
    blurView.contentView.addSubview(buttonStack)
    buttonStack.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      buttonStack.leadingAnchor.constraint(equalTo: blurView.contentView.leadingAnchor, constant: 5),
      buttonStack.trailingAnchor.constraint(equalTo: blurView.contentView.trailingAnchor, constant: -5),
      buttonStack.topAnchor.constraint(equalTo: blurView.contentView.topAnchor, constant: 2),
      buttonStack.bottomAnchor.constraint(equalTo: blurView.contentView.bottomAnchor, constant: -2)
    ])

    let configs: [(String, String, Selector)] = [
      ("Back", "chevron.left", #selector(backTapped)),
      ("Forward", "chevron.right", #selector(forwardTapped)),
      ("Share", "square.and.arrow.up", #selector(shareTapped)),
      ("Bookmarks", "book", #selector(bookmarksTapped)),
      ("Tabs", "square.on.square", #selector(tabsTapped))
    ]
    for (title, symbol, action) in configs {
      let button = UIButton(type: .system)
      button.accessibilityLabel = title
      button.setImage(UIImage(systemName: symbol), for: .normal)
      button.addTarget(self, action: action, for: .touchUpInside)
      button.tintColor = UIColor { traits in
        traits.userInterfaceStyle == .dark
          ? UIColor(red: 0.36, green: 0.68, blue: 1, alpha: 1)
          : UIColor(red: 0.02, green: 0.35, blue: 0.85, alpha: 1)
      }
      button.imageView?.contentMode = .scaleAspectFit
      buttonStack.addArrangedSubview(button)
      iconButtons.append(button)
    }
    updateStyle()
  }

  private func updateStyle() {
    layer.borderWidth = 0.6
    layer.borderColor = UIColor { traits in
      (traits.userInterfaceStyle == .dark ? UIColor.white : UIColor.black).withAlphaComponent(0.12)
    }.cgColor
    layer.shadowColor = UIColor.black.cgColor
    layer.shadowOpacity = traitCollection.userInterfaceStyle == .dark ? 0.22 : 0.10
    layer.shadowRadius = 16
    layer.shadowOffset = CGSize(width: 0, height: 5)
    iconButtons.forEach {
      $0.setPreferredSymbolConfiguration(
        UIImage.SymbolConfiguration(pointSize: 19, weight: .regular),
        forImageIn: .normal
      )
    }
  }

  @objc private func backTapped() { browserDelegate?.browserToolbarDidTapBack() }
  @objc private func forwardTapped() { browserDelegate?.browserToolbarDidTapForward() }
  @objc private func shareTapped() { browserDelegate?.browserToolbarDidTapShare() }
  @objc private func bookmarksTapped() { browserDelegate?.browserToolbarDidTapBookmarks() }
  @objc private func tabsTapped() { browserDelegate?.browserToolbarDidTapTabs() }
}
