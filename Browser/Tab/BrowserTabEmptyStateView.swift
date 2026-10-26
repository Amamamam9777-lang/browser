import UIKit

/// A native dark Safari-like start page. The browser content remains a WKWebView;
/// this view is only the new-tab surface shown while a tab has no loaded URL.
final class BrowserTabEmptyStateView: UIView {
  let imageView = UIImageView()
  var onOpenURL: ((URL) -> Void)?

  private let scrollView = UIScrollView()
  private let contentStack = UIStackView()
  private let customizeCard = UIView()
  private let favoriteURLs: [URL] = [
    URL(string: "https://www.apple.com")!,
    URL(string: "https://yandex.com")!,
    URL(string: "https://www.bing.com")!,
    URL(string: "https://www.google.com")!,
    URL(string: "https://www.apple.com")!,
    URL(string: "https://yandex.com")!,
    URL(string: "https://www.bing.com")!,
    URL(string: "https://www.google.com")!
  ]

  override init(frame: CGRect) {
    super.init(frame: frame)
    setupView()
  }

  required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

  private func setupView() {
    backgroundColor = UIColor(red: 0.035, green: 0.035, blue: 0.04, alpha: 1)
    scrollView.backgroundColor = .clear
    scrollView.showsVerticalScrollIndicator = false
    scrollView.alwaysBounceVertical = true
    scrollView.contentInset.bottom = 136
    addSubview(scrollView)
    scrollView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      scrollView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 5),
      scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
      scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
      scrollView.bottomAnchor.constraint(equalTo: bottomAnchor)
    ])

    contentStack.axis = .vertical
    contentStack.spacing = 30
    contentStack.alignment = .fill
    contentStack.translatesAutoresizingMaskIntoConstraints = false
    scrollView.addSubview(contentStack)
    NSLayoutConstraint.activate([
      contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 10),
      contentStack.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor, constant: 20),
      contentStack.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor, constant: -20),
      contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -24)
    ])

    buildCustomizeCard()
    buildFavoritesSection()
    buildPrivacySection()
    buildReadingListSection()
  }

  private func buildCustomizeCard() {
    customizeCard.backgroundColor = UIColor(red: 0.105, green: 0.105, blue: 0.115, alpha: 1)
    customizeCard.layer.cornerRadius = 28
    customizeCard.layer.cornerCurve = .continuous
    customizeCard.layer.borderWidth = 0.5
    customizeCard.layer.borderColor = UIColor.white.withAlphaComponent(0.045).cgColor
    contentStack.addArrangedSubview(customizeCard)

    let heading = UILabel()
    heading.text = "Start Page"
    heading.textColor = .white
    heading.font = .systemFont(ofSize: 17, weight: .semibold)
    heading.textAlignment = .center

    let closeButton = UIButton(type: .system)
    closeButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
    closeButton.tintColor = UIColor(white: 0.66, alpha: 1)
    closeButton.addTarget(self, action: #selector(closeCustomizeCard), for: .touchUpInside)
    closeButton.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([closeButton.widthAnchor.constraint(equalToConstant: 26), closeButton.heightAnchor.constraint(equalToConstant: 26)])

    let header = UIStackView(arrangedSubviews: [UIView(), heading, UIView(), closeButton])
    header.axis = .horizontal
    header.alignment = .center
    header.distribution = .equalSpacing

    let art = StartPageArtworkView()
    art.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([art.heightAnchor.constraint(equalToConstant: 112)])

    let description = UILabel()
    description.text = "Customise your wallpaper and sections that appear when creating new tabs."
    description.textColor = UIColor(white: 0.66, alpha: 1)
    description.font = .systemFont(ofSize: 14, weight: .regular)
    description.textAlignment = .center
    description.numberOfLines = 2

    let customizeButton = UIButton(type: .system)
    customizeButton.setTitle("Customise Start Page", for: .normal)
    customizeButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
    customizeButton.setTitleColor(.white, for: .normal)
    customizeButton.backgroundColor = UIColor(red: 0.19, green: 0.47, blue: 0.98, alpha: 1)
    customizeButton.layer.cornerRadius = 23
    customizeButton.layer.cornerCurve = .continuous
    customizeButton.heightAnchor.constraint(equalToConstant: 44).isActive = true
    customizeButton.addTarget(self, action: #selector(closeCustomizeCard), for: .touchUpInside)

    let stack = UIStackView(arrangedSubviews: [header, art, description, customizeButton])
    stack.axis = .vertical
    stack.spacing = 14
    stack.alignment = .fill
    stack.translatesAutoresizingMaskIntoConstraints = false
    customizeCard.addSubview(stack)
    NSLayoutConstraint.activate([
      stack.topAnchor.constraint(equalTo: customizeCard.topAnchor, constant: 20),
      stack.leadingAnchor.constraint(equalTo: customizeCard.leadingAnchor, constant: 18),
      stack.trailingAnchor.constraint(equalTo: customizeCard.trailingAnchor, constant: -18),
      stack.bottomAnchor.constraint(equalTo: customizeCard.bottomAnchor, constant: -18)
    ])
  }

  private func buildFavoritesSection() {
    let icon = UIImageView(image: UIImage(systemName: "person.fill"))
    icon.tintColor = .white
    icon.contentMode = .scaleAspectFit
    icon.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([icon.widthAnchor.constraint(equalToConstant: 20), icon.heightAnchor.constraint(equalToConstant: 22)])
    let title = UILabel()
    title.text = "Favourites"
    title.textColor = .white
    title.font = .systemFont(ofSize: 23, weight: .bold)
    let showAll = UIButton(type: .system)
    showAll.setTitle("Show All  ›", for: .normal)
    showAll.setTitleColor(UIColor(red: 0.36, green: 0.62, blue: 1, alpha: 1), for: .normal)
    showAll.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
    let header = UIStackView(arrangedSubviews: [icon, title, UIView(), showAll])
    header.axis = .horizontal
    header.alignment = .center
    header.spacing = 8

    let firstRow = makeFavoriteRow(startIndex: 0)
    let secondRow = makeFavoriteRow(startIndex: 4)
    let rows = UIStackView(arrangedSubviews: [firstRow, secondRow])
    rows.axis = .vertical
    rows.spacing = 18

    let section = UIStackView(arrangedSubviews: [header, rows])
    section.axis = .vertical
    section.spacing = 16
    contentStack.addArrangedSubview(section)
  }

  private func makeFavoriteRow(startIndex: Int) -> UIStackView {
    let names = ["Apple", "Yandex", "Bing", "Google"]
    let keys = ["apple", "yandex", "bing", "google"]
    let row = UIStackView()
    row.axis = .horizontal
    row.distribution = .fillEqually
    row.alignment = .top
    row.spacing = 14
    for column in 0..<4 {
      let index = startIndex + column
      let item = FavoriteShortcutButton(name: names[column], iconKey: keys[column])
      item.tag = index
      item.addTarget(self, action: #selector(favoriteTapped(_:)), for: .touchUpInside)
      row.addArrangedSubview(item)
    }
    return row
  }

  private func buildPrivacySection() {
    let heading = UILabel()
    heading.text = "Privacy Report"
    heading.textColor = .white
    heading.font = .systemFont(ofSize: 23, weight: .bold)

    let shield = UIImageView(image: UIImage(systemName: "hand.raised.fill"))
    shield.tintColor = .white
    shield.contentMode = .scaleAspectFit
    shield.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([shield.widthAnchor.constraint(equalToConstant: 28), shield.heightAnchor.constraint(equalToConstant: 30)])
    let count = UILabel()
    count.text = "10"
    count.textColor = .white
    count.font = .systemFont(ofSize: 22, weight: .regular)
    let left = UIStackView(arrangedSubviews: [shield, count])
    left.axis = .horizontal
    left.alignment = .center
    left.spacing = 7

    let description = UILabel()
    description.text = "In the last seven days, Safari has prevented 10 trackers from profiling you."
    description.textColor = UIColor(white: 0.9, alpha: 1)
    description.font = .systemFont(ofSize: 16, weight: .regular)
    description.numberOfLines = 3

    let report = UIStackView(arrangedSubviews: [left, description])
    report.axis = .horizontal
    report.alignment = .center
    report.spacing = 18
    report.layoutMargins = UIEdgeInsets(top: 20, left: 18, bottom: 20, right: 18)
    report.isLayoutMarginsRelativeArrangement = true
    report.backgroundColor = UIColor(red: 0.115, green: 0.115, blue: 0.125, alpha: 1)
    report.layer.cornerRadius = 22
    report.layer.cornerCurve = .continuous
    let fixedLeft = left.widthAnchor.constraint(equalToConstant: 92)
    fixedLeft.isActive = true

    let section = UIStackView(arrangedSubviews: [heading, report])
    section.axis = .vertical
    section.spacing = 14
    contentStack.addArrangedSubview(section)
  }

  private func buildReadingListSection() {
    let heading = UILabel()
    heading.text = "Reading List"
    heading.textColor = .white
    heading.font = .systemFont(ofSize: 23, weight: .bold)
    let description = UILabel()
    description.text = "Reading List lets you collect webpages and links to read later. Tap the Share button to add the current page."
    description.textColor = UIColor(white: 0.57, alpha: 1)
    description.font = .systemFont(ofSize: 16, weight: .regular)
    description.numberOfLines = 0
    description.setContentHuggingPriority(.defaultLow, for: .vertical)
    description.layoutMargins = UIEdgeInsets(top: 0, left: 30, bottom: 0, right: 0)
    let section = UIStackView(arrangedSubviews: [heading, description])
    section.axis = .vertical
    section.spacing = 24
    contentStack.addArrangedSubview(section)
  }

  @objc private func closeCustomizeCard() {
    UIView.animate(withDuration: 0.22, delay: 0, options: [.curveEaseInOut]) {
      self.customizeCard.alpha = 0
      self.customizeCard.transform = CGAffineTransform(scaleX: 0.98, y: 0.98)
    } completion: { _ in
      self.customizeCard.isHidden = true
    }
  }

  @objc private func favoriteTapped(_ sender: FavoriteShortcutButton) {
    guard favoriteURLs.indices.contains(sender.tag) else { return }
    onOpenURL?(favoriteURLs[sender.tag])
  }
}

private final class FavoriteShortcutButton: UIControl {
  init(name: String, iconKey: String) {
    super.init(frame: .zero)
    let icon = UIView()
    icon.backgroundColor = .white
    icon.layer.cornerRadius = 16
    icon.layer.cornerCurve = .continuous
    icon.layer.borderWidth = 0.5
    icon.layer.borderColor = UIColor.white.withAlphaComponent(0.16).cgColor
    icon.translatesAutoresizingMaskIntoConstraints = false
    addSubview(icon)
    NSLayoutConstraint.activate([
      icon.topAnchor.constraint(equalTo: topAnchor),
      icon.centerXAnchor.constraint(equalTo: centerXAnchor),
      icon.widthAnchor.constraint(equalToConstant: 60),
      icon.heightAnchor.constraint(equalToConstant: 60)
    ])

    if iconKey == "apple" {
      let image = UIImageView(image: UIImage(systemName: "apple.logo"))
      image.tintColor = UIColor(white: 0.35, alpha: 1)
      image.contentMode = .scaleAspectFit
      image.translatesAutoresizingMaskIntoConstraints = false
      icon.addSubview(image)
      NSLayoutConstraint.activate([image.centerXAnchor.constraint(equalTo: icon.centerXAnchor), image.centerYAnchor.constraint(equalTo: icon.centerYAnchor), image.widthAnchor.constraint(equalToConstant: 37), image.heightAnchor.constraint(equalToConstant: 40)])
    } else if iconKey == "yandex" {
      icon.backgroundColor = UIColor(red: 0.92, green: 0.13, blue: 0.17, alpha: 1)
      let label = UILabel()
      label.text = "Я"
      label.font = .systemFont(ofSize: 39, weight: .medium)
      label.textColor = .white
      label.textAlignment = .center
      label.translatesAutoresizingMaskIntoConstraints = false
      icon.addSubview(label)
      NSLayoutConstraint.activate([label.centerXAnchor.constraint(equalTo: icon.centerXAnchor), label.centerYAnchor.constraint(equalTo: icon.centerYAnchor, constant: -1)])
    } else if iconKey == "bing" {
      let label = UILabel()
      label.text = "b"
      label.font = .systemFont(ofSize: 42, weight: .medium)
      label.textColor = UIColor(red: 0.0, green: 0.57, blue: 0.88, alpha: 1)
      label.textAlignment = .center
      label.translatesAutoresizingMaskIntoConstraints = false
      icon.addSubview(label)
      NSLayoutConstraint.activate([label.centerXAnchor.constraint(equalTo: icon.centerXAnchor), label.centerYAnchor.constraint(equalTo: icon.centerYAnchor, constant: -2)])
    } else {
      let label = UILabel()
      label.text = "G"
      label.font = .systemFont(ofSize: 43, weight: .bold)
      label.textColor = UIColor(red: 0.26, green: 0.52, blue: 0.96, alpha: 1)
      label.textAlignment = .center
      label.translatesAutoresizingMaskIntoConstraints = false
      icon.addSubview(label)
      NSLayoutConstraint.activate([label.centerXAnchor.constraint(equalTo: icon.centerXAnchor), label.centerYAnchor.constraint(equalTo: icon.centerYAnchor, constant: -2)])
    }

    let title = UILabel()
    title.text = name
    title.textColor = UIColor(white: 0.93, alpha: 1)
    title.font = .systemFont(ofSize: 12, weight: .medium)
    title.textAlignment = .center
    title.translatesAutoresizingMaskIntoConstraints = false
    addSubview(title)
    NSLayoutConstraint.activate([
      title.topAnchor.constraint(equalTo: icon.bottomAnchor, constant: 7),
      title.leadingAnchor.constraint(equalTo: leadingAnchor),
      title.trailingAnchor.constraint(equalTo: trailingAnchor),
      title.bottomAnchor.constraint(equalTo: bottomAnchor)
    ])
  }
  required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

private final class StartPageArtworkView: UIView {
  private let gradient = CAGradientLayer()
  private let centerGlass = UIVisualEffectView(effect: nil)
  private let nameLabel = UILabel()
  private let suggestionLabel = UILabel()
  private var tiles = [UIView]()

  override init(frame: CGRect) {
    super.init(frame: frame)
    layer.cornerRadius = 17
    layer.cornerCurve = .continuous
    clipsToBounds = true
    gradient.colors = [
      UIColor(red: 0.92, green: 0.50, blue: 0.39, alpha: 1).cgColor,
      UIColor(red: 0.91, green: 0.59, blue: 0.70, alpha: 1).cgColor,
      UIColor(red: 0.30, green: 0.40, blue: 0.88, alpha: 1).cgColor
    ]
    gradient.startPoint = CGPoint(x: 0, y: 0.35)
    gradient.endPoint = CGPoint(x: 1, y: 0.65)
    layer.addSublayer(gradient)

    let diagonal = UIView()
    diagonal.backgroundColor = UIColor(red: 0.14, green: 0.77, blue: 0.55, alpha: 0.62)
    diagonal.transform = CGAffineTransform(rotationAngle: -0.35)
    addSubview(diagonal)
    diagonal.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([diagonal.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 15), diagonal.topAnchor.constraint(equalTo: topAnchor, constant: -25), diagonal.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 22), diagonal.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.28)])

    if #available(iOS 26.0, *) {
      let glassEffect = UIGlassEffect(style: .regular)
      centerGlass.effect = glassEffect
    } else {
      centerGlass.effect = UIBlurEffect(style: .systemThinMaterialDark)
    }
    centerGlass.clipsToBounds = true
    centerGlass.layer.cornerRadius = 16
    centerGlass.layer.cornerCurve = .continuous
    centerGlass.layer.borderWidth = 0.5
    centerGlass.layer.borderColor = UIColor.white.withAlphaComponent(0.25).cgColor
    addSubview(centerGlass)
    centerGlass.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      centerGlass.centerXAnchor.constraint(equalTo: centerXAnchor),
      centerGlass.topAnchor.constraint(equalTo: topAnchor, constant: -7),
      centerGlass.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 8),
      centerGlass.widthAnchor.constraint(equalToConstant: 124)
    ])

    nameLabel.text = "Favourites"
    suggestionLabel.text = "Suggestions"
    [nameLabel, suggestionLabel].forEach {
      $0.textColor = .white
      $0.font = .systemFont(ofSize: 9, weight: .medium)
    }
    let tileGrid = UIStackView()
    tileGrid.axis = .vertical
    tileGrid.spacing = 5
    for _ in 0..<2 {
      let row = UIStackView()
      row.axis = .horizontal
      row.distribution = .fillEqually
      row.spacing = 5
      for _ in 0..<4 {
        let tile = UIView()
        tile.backgroundColor = UIColor.white.withAlphaComponent(0.28)
        tile.layer.cornerRadius = 5
        row.addArrangedSubview(tile)
      }
      tileGrid.addArrangedSubview(row)
    }
    let miniStack = UIStackView(arrangedSubviews: [nameLabel, tileGrid, suggestionLabel])
    miniStack.axis = .vertical
    miniStack.spacing = 4
    miniStack.translatesAutoresizingMaskIntoConstraints = false
    centerGlass.contentView.addSubview(miniStack)
    NSLayoutConstraint.activate([
      miniStack.topAnchor.constraint(equalTo: centerGlass.contentView.topAnchor, constant: 26),
      miniStack.leadingAnchor.constraint(equalTo: centerGlass.contentView.leadingAnchor, constant: 12),
      miniStack.trailingAnchor.constraint(equalTo: centerGlass.contentView.trailingAnchor, constant: -12),
      tileGrid.heightAnchor.constraint(equalToConstant: 36)
    ])
  }

  required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
  override func layoutSubviews() {
    super.layoutSubviews()
    gradient.frame = bounds
  }
}
