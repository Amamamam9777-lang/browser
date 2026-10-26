// Safari-style floating control row. On iOS 26 each control owns a real
// UIGlassEffect so the address field and the two round controls remain distinct.
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

  private let backGlass = UIVisualEffectView(effect: nil)
  private let menuGlass = UIVisualEffectView(effect: nil)
  private let backButton = UIButton(type: .system)
  private let menuButton = UIButton(type: .system)

  override init(frame: CGRect) {
    super.init(frame: frame)
    setupView()
  }

  required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

  override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)
    updateGlassEffects()
  }

  private func setupView() {
    backgroundColor = .clear
    isOpaque = false
    clipsToBounds = false

    configureGlass(backGlass)
    configureGlass(menuGlass)
    addSubview(backGlass)
    addSubview(menuGlass)
    backGlass.translatesAutoresizingMaskIntoConstraints = false
    menuGlass.translatesAutoresizingMaskIntoConstraints = false

    NSLayoutConstraint.activate([
      backGlass.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 1),
      backGlass.centerYAnchor.constraint(equalTo: centerYAnchor),
      backGlass.widthAnchor.constraint(equalToConstant: 56),
      backGlass.heightAnchor.constraint(equalToConstant: 56),
      menuGlass.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -1),
      menuGlass.centerYAnchor.constraint(equalTo: centerYAnchor),
      menuGlass.widthAnchor.constraint(equalToConstant: 56),
      menuGlass.heightAnchor.constraint(equalToConstant: 56)
    ])

    configureButton(backButton, symbol: "chevron.left", label: "Back")
    configureButton(menuButton, symbol: "ellipsis", label: "More")
    backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
    menuButton.addTarget(self, action: #selector(menuTapped), for: .touchUpInside)
    backGlass.contentView.addSubview(backButton)
    menuGlass.contentView.addSubview(menuButton)
    backButton.translatesAutoresizingMaskIntoConstraints = false
    menuButton.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      backButton.leadingAnchor.constraint(equalTo: backGlass.contentView.leadingAnchor),
      backButton.trailingAnchor.constraint(equalTo: backGlass.contentView.trailingAnchor),
      backButton.topAnchor.constraint(equalTo: backGlass.contentView.topAnchor),
      backButton.bottomAnchor.constraint(equalTo: backGlass.contentView.bottomAnchor),
      menuButton.leadingAnchor.constraint(equalTo: menuGlass.contentView.leadingAnchor),
      menuButton.trailingAnchor.constraint(equalTo: menuGlass.contentView.trailingAnchor),
      menuButton.topAnchor.constraint(equalTo: menuGlass.contentView.topAnchor),
      menuButton.bottomAnchor.constraint(equalTo: menuGlass.contentView.bottomAnchor)
    ])
    updateGlassEffects()
  }

  private func configureGlass(_ glass: UIVisualEffectView) {
    glass.clipsToBounds = true
    glass.layer.cornerRadius = 28
    glass.layer.cornerCurve = .continuous
    glass.isUserInteractionEnabled = true
  }

  private func configureButton(_ button: UIButton, symbol: String, label: String) {
    button.accessibilityLabel = label
    button.tintColor = .label
    button.setImage(UIImage(systemName: symbol), for: .normal)
    button.imageView?.contentMode = .scaleAspectFit
    button.setPreferredSymbolConfiguration(
      UIImage.SymbolConfiguration(pointSize: symbol == "ellipsis" ? 22 : 24, weight: .regular),
      forImageIn: .normal
    )
  }

  private func updateGlassEffects() {
    if #available(iOS 26.0, *) {
      let backEffect = UIGlassEffect(style: .regular)
      backEffect.isInteractive = true
      backGlass.effect = backEffect
      let menuEffect = UIGlassEffect(style: .regular)
      menuEffect.isInteractive = true
      menuGlass.effect = menuEffect
    } else {
      backGlass.effect = UIBlurEffect(style: .systemChromeMaterial)
      menuGlass.effect = UIBlurEffect(style: .systemChromeMaterial)
    }
  }

  @objc private func backTapped() { browserDelegate?.browserToolbarDidTapBack() }
  @objc private func menuTapped() { browserDelegate?.browserToolbarDidTapTabs() }
}
