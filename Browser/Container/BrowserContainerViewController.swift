//
//  BrowserContainerViewController.swift
//  Browser
//
//  Created by Amer Hukić on 10. 9. 2021..
//

import UIKit

class BrowserContainerViewController: UIViewController {
  let contentView = BrowserContainerContentView()
  var tabViewControllers = [BrowserTabViewController]()
  let viewModel: BrowserContainerViewModel
  
  // Address bar animation properties
  var isAddressBarActive = false
  var hasHiddenTab = false
  var currentTabIndex = 0 {
    didSet {
      updateAddressBarsAfterTabChange()
      setNeedsStatusBarAppearanceUpdate()
    }
  }
  
  // Toolbar animation properties
  var collapsingToolbarAnimator: UIViewPropertyAnimator?
  var expandingToolbarAnimator: UIViewPropertyAnimator?
  var isCollapsed = false
  
  var currentAddressBar: BrowserAddressBar {
    contentView.addressBars[currentTabIndex]
  }
  
  var leftAddressBar: BrowserAddressBar? {
    contentView.addressBars[safe: currentTabIndex - 1]
  }
  
  var rightAddressBar: BrowserAddressBar? {
    contentView.addressBars[safe: currentTabIndex + 1]
  }
  
  override var childForStatusBarStyle: UIViewController? {
    tabViewControllers[safe: currentTabIndex]
  }
  
  init(viewModel: BrowserContainerViewModel = .init()) {
    self.viewModel = viewModel
    super.init(nibName: nil, bundle: nil)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func loadView() {
    view = contentView
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    view.overrideUserInterfaceStyle = .dark
    contentView.overrideUserInterfaceStyle = .dark
    setupCancelButton()
    contentView.toolbar.browserDelegate = self
    setupAddressBarsScrollView()
    setupAddressBarsExpandingOnTap()
    setupKeyboardManager()
    openNewTab(isHidden: false)
  }
  
  func setCancelButtonHidden(_ isHidden: Bool) {
    UIView.animate(withDuration: 0.1) {
      self.contentView.cancelButton.alpha = isHidden ? 0 : 1
    }
  }

  func openIncomingURL(_ url: URL) {
    if !isViewLoaded { loadViewIfNeeded() }
    if tabViewControllers.isEmpty { openNewTab(isHidden: false) }
    let tab = tabViewControllers[currentTabIndex]
    tab.loadWebsite(from: url)
    currentAddressBar.setDisplayedDomain(viewModel.getDomain(from: url))
    dismissKeyboard()
  }
}

// MARK: Helper methods
private extension BrowserContainerViewController {
  func setupAddressBarsScrollView() {
    contentView.addressBarsScrollView.delegate = self
  }
  
  func setupCancelButton() {
    contentView.cancelButton.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
  }
  
  func openNewTab(isHidden: Bool) {
    addTabViewController(isHidden: isHidden)
    addAddressBar(isHidden: isHidden)
  }
  
  func addTabViewController(isHidden: Bool) {
    let tabViewController = BrowserTabViewController()
    tabViewController.view.alpha = isHidden ? 0 : 1
    tabViewController.view.transform = isHidden ? CGAffineTransform(scaleX: 0.8, y: 0.8) : .identity
    tabViewController.showEmptyState()
    tabViewController.delegate = self
    tabViewControllers.append(tabViewController)
    contentView.tabsStackView.addArrangedSubview(tabViewController.view)
    tabViewController.view.snp.makeConstraints {
      $0.width.equalTo(contentView)
    }
    addChild(tabViewController)
    tabViewController.didMove(toParent: self)
  }
  
  func addAddressBar(isHidden: Bool) {
    let addressBar = BrowserAddressBar()
    addressBar.delegate = self
    contentView.addressBarsStackView.addArrangedSubview(addressBar)
    addressBar.snp.makeConstraints {
      $0.width.equalTo(contentView.addressBarsScrollView).offset(-contentView.addressBarsStackViewSidePadding * 2)
    }
    
    if isHidden {
      hasHiddenTab = true
      addressBar.containerViewWidthConstraint?.update(offset: contentView.addressBarContainerHidingWidthOffset)
      addressBar.containerView.alpha = 0
      addressBar.plusOverlayView.alpha = 1
    }
  }
  
  func dismissKeyboard() {
    view.endEditing(true)
  }
  
  func updateAddressBarsAfterTabChange() {
    currentAddressBar.setSideButtonsHidden(false)
    currentAddressBar.isUserInteractionEnabled = true
    leftAddressBar?.setSideButtonsHidden(true)
    leftAddressBar?.isUserInteractionEnabled = false
    rightAddressBar?.setSideButtonsHidden(true)
    rightAddressBar?.isUserInteractionEnabled = false
  }
  
  func setupAddressBarsExpandingOnTap() {
    let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(addressBarScrollViewTapped))
    contentView.addressBarsScrollView.addGestureRecognizer(tapGestureRecognizer)
  }
}

// MARK: Action methods
private extension BrowserContainerViewController {
  @objc func cancelButtonTapped() {
    dismissKeyboard()
  }
  
  @objc func addressBarScrollViewTapped() {
    guard isCollapsed else { return }
    setupExpandingToolbarAnimator()
    expandingToolbarAnimator?.startAnimation()
    isCollapsed = false
  }
}

// MARK: BrowserAddressBarDelegate
extension BrowserContainerViewController: BrowserAddressBarDelegate {
  func addressBarDidBeginEditing() {
    isAddressBarActive = true
  }

  func addressBarDidTapPageMenu(_ addressBar: BrowserAddressBar) {
    guard tabViewControllers[safe: currentTabIndex]?.hasLoadedUrl == true else { return }
    presentPageActionsMenu()
  }

  func addressBar(_ addressBar: BrowserAddressBar, didReturnWithText text: String) {
    let tabViewController = tabViewControllers[currentTabIndex]
    if let url = self.viewModel.getURL(for: text) {
      addressBar.setDisplayedDomain(viewModel.getDomain(from: url))
      tabViewController.loadWebsite(from: url)
    }
    dismissKeyboard()
  }
}


extension BrowserContainerViewController: BrowserToolbarDelegate {
  func browserToolbarDidTapBack() {
    if let tab = tabViewControllers[safe: currentTabIndex] { tab.goBackIfPossible() }
  }
  func browserToolbarDidTapForward() { tabViewControllers[safe: currentTabIndex]?.goForwardIfPossible() }
  func browserToolbarDidTapShare() {
    guard let url = tabViewControllers[safe: currentTabIndex]?.currentURL else { return }
    let sheet = UIActivityViewController(activityItems: [url], applicationActivities: nil)
    if let popover = sheet.popoverPresentationController { popover.sourceView = contentView.toolbar; popover.sourceRect = contentView.toolbar.bounds }
    present(sheet, animated: true)
  }
  func browserToolbarDidTapBookmarks() {
    let alert = UIAlertController(title: "Bookmarks", message: "Bookmark management is not part of this project yet.", preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: "OK", style: .default))
    present(alert, animated: true)
  }
  func browserToolbarDidTapTabs() {
    // The ellipsis opens browser/tab actions. Page actions such as Hide
    // Distracting Items belong to the aA button beside the current domain.
    presentBrowserMenu()
  }

  private func presentBrowserMenu() {
    let menu = BrowserSafariMenuViewController(isOnWebPage: false)
    menu.onAllTabs = { [weak self] in self?.presentTabsOverview() }
    menu.onNewTab = { [weak self] in self?.createAndSelectNewTab() }
    menu.onBookmarks = { [weak self] in self?.browserToolbarDidTapBookmarks() }
    menu.modalPresentationStyle = .overFullScreen
    menu.modalTransitionStyle = .crossDissolve
    present(menu, animated: true)
  }

  private func presentPageActionsMenu() {
    let menu = BrowserSafariMenuViewController(isOnWebPage: true)
    menu.modalPresentationStyle = .overFullScreen
    menu.modalTransitionStyle = .crossDissolve
    present(menu, animated: true)
  }

  private func createAndSelectNewTab() {
    openNewTab(isHidden: false)
    view.layoutIfNeeded()
    let index = tabViewControllers.count - 1
    currentTabIndex = index
    contentView.addressBarsScrollView.setContentOffset(CGPoint(x: CGFloat(index) * contentView.addressBarPageWidth, y: 0), animated: false)
    contentView.tabsScrollView.setContentOffset(CGPoint(x: CGFloat(index) * (contentView.frame.width + contentView.tabsStackViewSpacing), y: 0), animated: false)
  }

  private func presentTabsOverview() {
    view.layoutIfNeeded()
    let overview = BrowserTabsOverviewViewController(
      tabs: tabViewControllers,
      selectedIndex: currentTabIndex,
      onSelect: { [weak self] index in
        guard let self, index >= 0, index < self.tabViewControllers.count else { return }
        self.currentTabIndex = index
        self.contentView.addressBarsScrollView.setContentOffset(CGPoint(x: CGFloat(index) * self.contentView.addressBarPageWidth, y: 0), animated: false)
        self.contentView.tabsScrollView.setContentOffset(CGPoint(x: CGFloat(index) * (self.contentView.frame.width + self.contentView.tabsStackViewSpacing), y: 0), animated: false)
      },
      onNewTab: { [weak self] in self?.createAndSelectNewTab() })
    overview.modalPresentationStyle = .pageSheet
    if let sheet = overview.sheetPresentationController {
      sheet.detents = [.large()]
      sheet.prefersGrabberVisible = true
      sheet.preferredCornerRadius = 30
    }
    present(overview, animated: true)
  }
}

/// A visual tab switcher inspired by Safari's card overview.
private final class BrowserTabsOverviewViewController: UIViewController {
  private let tabs: [BrowserTabViewController]
  private let selectedIndex: Int
  private let onSelect: (Int) -> Void
  private let onNewTab: () -> Void
  private let stack = UIStackView()

  init(tabs: [BrowserTabViewController], selectedIndex: Int, onSelect: @escaping (Int) -> Void, onNewTab: @escaping () -> Void) {
    self.tabs = tabs
    self.selectedIndex = selectedIndex
    self.onSelect = onSelect
    self.onNewTab = onNewTab
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = UIColor { $0.userInterfaceStyle == .dark ? UIColor(white: 0.055, alpha: 1) : UIColor(white: 0.95, alpha: 1) }
    let title = UILabel()
    title.text = "Tabs"
    title.font = .systemFont(ofSize: 30, weight: .bold)
    title.textColor = .label
    let count = UILabel()
    count.text = "\(tabs.count) open"
    count.font = .systemFont(ofSize: 14, weight: .medium)
    count.textColor = .secondaryLabel
    let header = UIStackView(arrangedSubviews: [title, UIView(), count])
    header.alignment = .center
    header.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(header)
    NSLayoutConstraint.activate([header.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 18), header.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 22), header.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -22)])

    let scroll = UIScrollView()
    scroll.alwaysBounceVertical = true
    scroll.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(scroll)
    stack.axis = .vertical
    stack.spacing = 16
    stack.translatesAutoresizingMaskIntoConstraints = false
    scroll.addSubview(stack)
    NSLayoutConstraint.activate([scroll.topAnchor.constraint(equalTo: header.bottomAnchor, constant: 18), scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 18), scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -18), scroll.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -86), stack.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor), stack.leadingAnchor.constraint(equalTo: scroll.contentLayoutGuide.leadingAnchor), stack.trailingAnchor.constraint(equalTo: scroll.contentLayoutGuide.trailingAnchor), stack.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor), stack.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor)])

    for index in tabs.indices { stack.addArrangedSubview(makeCard(for: index)) }
    let newButton = UIButton(type: .system)
    var config = UIButton.Configuration.filled()
    config.title = "New Tab"
    config.image = UIImage(systemName: "plus")
    config.imagePadding = 8
    config.cornerStyle = .capsule
    config.baseBackgroundColor = .systemBlue
    config.baseForegroundColor = .white
    config.contentInsets = NSDirectionalEdgeInsets(top: 15, leading: 22, bottom: 15, trailing: 22)
    newButton.configuration = config
    newButton.addTarget(self, action: #selector(newTabTapped), for: .touchUpInside)
    newButton.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(newButton)
    NSLayoutConstraint.activate([newButton.centerXAnchor.constraint(equalTo: view.centerXAnchor), newButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -14)])
  }

  private func makeCard(for index: Int) -> UIView {
    let tab = tabs[index]
    let card = UIView()
    card.backgroundColor = UIColor(red: 0.105, green: 0.105, blue: 0.115, alpha: 1)
    card.layer.cornerRadius = 27
    card.layer.cornerCurve = .continuous
    card.layer.borderWidth = index == selectedIndex ? 2 : 0.5
    card.layer.borderColor = (index == selectedIndex ? UIColor.systemBlue : UIColor.separator).cgColor
    card.clipsToBounds = true

    let preview = UIView()
    preview.backgroundColor = UIColor { $0.userInterfaceStyle == .dark ? UIColor(white: 0.12, alpha: 1) : UIColor(white: 1, alpha: 1) }
    preview.translatesAutoresizingMaskIntoConstraints = false
    card.addSubview(preview)
    NSLayoutConstraint.activate([preview.topAnchor.constraint(equalTo: card.topAnchor), preview.leadingAnchor.constraint(equalTo: card.leadingAnchor), preview.trailingAnchor.constraint(equalTo: card.trailingAnchor), preview.heightAnchor.constraint(equalToConstant: 190)])
    let snapshotImageView = UIImageView()
    snapshotImageView.contentMode = .scaleAspectFill
    snapshotImageView.clipsToBounds = true
    snapshotImageView.backgroundColor = UIColor(white: 0.08, alpha: 1)
    snapshotImageView.translatesAutoresizingMaskIntoConstraints = false
    preview.addSubview(snapshotImageView)
    NSLayoutConstraint.activate([
      snapshotImageView.topAnchor.constraint(equalTo: preview.topAnchor),
      snapshotImageView.leadingAnchor.constraint(equalTo: preview.leadingAnchor),
      snapshotImageView.trailingAnchor.constraint(equalTo: preview.trailingAnchor),
      snapshotImageView.bottomAnchor.constraint(equalTo: preview.bottomAnchor)
    ])
    let globe = UIImageView(image: UIImage(systemName: tab.hasLoadedUrl ? "globe" : "safari.fill"))
    globe.tintColor = UIColor(white: 0.68, alpha: 1)
    globe.contentMode = .scaleAspectFit
    globe.translatesAutoresizingMaskIntoConstraints = false
    preview.addSubview(globe)
    NSLayoutConstraint.activate([globe.centerXAnchor.constraint(equalTo: preview.centerXAnchor), globe.centerYAnchor.constraint(equalTo: preview.centerYAnchor), globe.widthAnchor.constraint(equalToConstant: 42), globe.heightAnchor.constraint(equalToConstant: 42)])
    tab.captureTabSnapshot { image in
      DispatchQueue.main.async {
        if let image {
          snapshotImageView.image = image
          globe.isHidden = true
        }
      }
    }
    let title = UILabel()
    title.text = tab.currentURL?.host ?? (tab.hasLoadedUrl ? (tab.currentURL?.absoluteString ?? "Webpage") : "Favorites")
    title.font = .systemFont(ofSize: 15, weight: .semibold)
    title.textColor = .label
    title.lineBreakMode = .byTruncatingTail
    let subtitle = UILabel()
    subtitle.text = index == selectedIndex ? "Current Tab" : "Tab \(index + 1)"
    subtitle.font = .systemFont(ofSize: 12, weight: .regular)
    subtitle.textColor = .secondaryLabel
    let labels = UIStackView(arrangedSubviews: [title, subtitle])
    labels.axis = .vertical
    labels.spacing = 4
    labels.layoutMargins = UIEdgeInsets(top: 10, left: 0, bottom: 0, right: 0)
    labels.isLayoutMarginsRelativeArrangement = true
    labels.translatesAutoresizingMaskIntoConstraints = false
    card.addSubview(labels)
    NSLayoutConstraint.activate([labels.topAnchor.constraint(equalTo: preview.bottomAnchor, constant: 10), labels.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 14), labels.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -14), labels.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -12)])
    let tap = UIControl()
    tap.backgroundColor = .clear
    tap.translatesAutoresizingMaskIntoConstraints = false
    tap.tag = index
    tap.addTarget(self, action: #selector(cardTapped(_:)), for: .touchUpInside)
    card.addSubview(tap)
    NSLayoutConstraint.activate([tap.topAnchor.constraint(equalTo: card.topAnchor), tap.leadingAnchor.constraint(equalTo: card.leadingAnchor), tap.trailingAnchor.constraint(equalTo: card.trailingAnchor), tap.bottomAnchor.constraint(equalTo: card.bottomAnchor)])
    return card
  }

  @objc private func cardTapped(_ sender: UIControl) {
    dismiss(animated: true) { self.onSelect(sender.tag) }
  }
  @objc private func newTabTapped() {
    dismiss(animated: true) { self.onNewTab() }
  }
}


/// A custom glass menu matching the floating, grouped menu in Safari on iOS 26.
/// It is a visual implementation; unavailable Safari-only extension actions are inert.
private final class BrowserSafariMenuViewController: UIViewController {
  var onAllTabs: (() -> Void)?
  var onNewTab: (() -> Void)?
  var onBookmarks: (() -> Void)?

  private let isOnWebPage: Bool
  private let panel = UIVisualEffectView(effect: nil)
  private let rowsStack = UIStackView()

  init(isOnWebPage: Bool) {
    self.isOnWebPage = isOnWebPage
    super.init(nibName: nil, bundle: nil)
    modalPresentationStyle = .overFullScreen
    modalTransitionStyle = .crossDissolve
  }

  required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .clear
    view.overrideUserInterfaceStyle = .dark

    let dimmer = UIControl()
    dimmer.backgroundColor = UIColor.black.withAlphaComponent(0.18)
    dimmer.addTarget(self, action: #selector(dismissMenu), for: .touchUpInside)
    dimmer.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(dimmer)
    NSLayoutConstraint.activate([
      dimmer.topAnchor.constraint(equalTo: view.topAnchor),
      dimmer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      dimmer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      dimmer.bottomAnchor.constraint(equalTo: view.bottomAnchor)
    ])

    configurePanelEffect()
    panel.clipsToBounds = true
    panel.layer.cornerRadius = 34
    panel.layer.cornerCurve = .continuous
    panel.layer.borderWidth = 0.7
    panel.layer.borderColor = UIColor.white.withAlphaComponent(0.16).cgColor
    panel.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(panel)

    rowsStack.axis = .vertical
    rowsStack.spacing = 8
    rowsStack.translatesAutoresizingMaskIntoConstraints = false
    panel.contentView.addSubview(rowsStack)
    NSLayoutConstraint.activate([
      panel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 11),
      panel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -11),
      panel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -4),
      panel.heightAnchor.constraint(equalToConstant: isOnWebPage ? 470 : 260),
      rowsStack.topAnchor.constraint(equalTo: panel.contentView.topAnchor, constant: 13),
      rowsStack.leadingAnchor.constraint(equalTo: panel.contentView.leadingAnchor, constant: 13),
      rowsStack.trailingAnchor.constraint(equalTo: panel.contentView.trailingAnchor, constant: -13),
      rowsStack.bottomAnchor.constraint(equalTo: panel.contentView.bottomAnchor, constant: -13)
    ])

    if isOnWebPage {
      buildWebsiteMenu()
    } else {
      buildStartPageMenu()
    }
  }

  private func configurePanelEffect() {
    if #available(iOS 26.0, *) {
      let effect = UIGlassEffect(style: .regular)
      panel.effect = effect
    } else {
      panel.effect = UIBlurEffect(style: .systemMaterialDark)
    }
  }

  private func buildStartPageMenu() {
    let group = makeGroup()
    group.addArrangedSubview(makeMenuRow(icon: "plus", title: "New Tab") { [weak self] in
      self?.dismiss(animated: true) { self?.onNewTab?() }
    })
    group.addArrangedSubview(makeSeparator())
    group.addArrangedSubview(makeMenuRow(icon: "hand.raised.fill", title: "New Private Tab") { [weak self] in
      self?.dismiss(animated: true) { self?.onNewTab?() }
    })
    rowsStack.addArrangedSubview(group)

    let bottomGroup = makeGroup()
    let footer = UIStackView()
    footer.axis = .horizontal
    footer.distribution = .fillEqually
    footer.alignment = .center
    footer.addArrangedSubview(makeLargeMenuAction(icon: "book.closed.fill", title: "Bookmarks") { [weak self] in
      self?.dismiss(animated: true) { self?.onBookmarks?() }
    })
    footer.addArrangedSubview(makeLargeMenuAction(icon: "square.on.square", title: "All Tabs") { [weak self] in
      self?.dismiss(animated: true) { self?.onAllTabs?() }
    })
    bottomGroup.addArrangedSubview(footer)
    rowsStack.addArrangedSubview(bottomGroup)
  }

  private func buildWebsiteMenu() {
    let mainGroup = makeGroup()
    let items: [(String, String)] = [
      ("eye.slash", "Hide Distracting Items"),
      ("hand.raised.slash", "Turn Off Content Blockers"),
      ("play.circle", "Play All Animations"),
      ("character.bubble", "Translate to English")
    ]
    for (index, item) in items.enumerated() {
      mainGroup.addArrangedSubview(makeMenuRow(icon: item.0, title: item.1) { [weak self] in
        self?.dismiss(animated: true)
      })
      if index != items.count - 1 { mainGroup.addArrangedSubview(makeSeparator()) }
    }
    rowsStack.addArrangedSubview(mainGroup)

    rowsStack.addArrangedSubview(makeGroupSingleRow(icon: "arrow.down.circle", title: "Downloads") { [weak self] in
      self?.dismiss(animated: true)
    })

    let extensions = makeGroup()
    extensions.addArrangedSubview(makeMenuRow(icon: "puzzlepiece.extension", title: "Manage Extensions") { [weak self] in
      self?.dismiss(animated: true)
    })
    rowsStack.addArrangedSubview(extensions)

    let footer = UIStackView()
    footer.axis = .horizontal
    footer.alignment = .center
    footer.spacing = 10
    footer.addArrangedSubview(makeFooterCircle(icon: "doc.text.magnifyingglass"))
    let textSize = UIStackView()
    textSize.axis = .horizontal
    textSize.distribution = .fillEqually
    textSize.alignment = .center
    textSize.backgroundColor = UIColor.white.withAlphaComponent(0.08)
    textSize.layer.cornerRadius = 28
    textSize.clipsToBounds = true
    textSize.addArrangedSubview(makeFooterLetter("A", size: 17))
    textSize.addArrangedSubview(makeFooterLetter("A", size: 22))
    footer.addArrangedSubview(textSize)
    footer.addArrangedSubview(makeFooterCircle(icon: "ellipsis"))
    textSize.heightAnchor.constraint(equalToConstant: 52).isActive = true
    footer.arrangedSubviews.first?.widthAnchor.constraint(equalToConstant: 52).isActive = true
    footer.arrangedSubviews.last?.widthAnchor.constraint(equalToConstant: 52).isActive = true
    rowsStack.addArrangedSubview(footer)
  }

  private func makeGroup() -> UIStackView {
    let group = UIStackView()
    group.axis = .vertical
    group.spacing = 0
    group.backgroundColor = UIColor.white.withAlphaComponent(0.055)
    group.layer.cornerRadius = 25
    group.layer.cornerCurve = .continuous
    group.clipsToBounds = true
    return group
  }

  private func makeGroupSingleRow(icon: String, title: String, action: @escaping () -> Void) -> UIView {
    let group = makeGroup()
    group.addArrangedSubview(makeMenuRow(icon: icon, title: title, action: action))
    return group
  }

  private func makeMenuRow(icon: String, title: String, tint: UIColor = .white, action: @escaping () -> Void) -> UIView {
    let button = ClosureActionControl(action: action)
    let image = UIImageView(image: UIImage(systemName: icon))
    image.tintColor = tint
    image.contentMode = .scaleAspectFit
    image.translatesAutoresizingMaskIntoConstraints = false
    button.addSubview(image)
    let label = UILabel()
    label.text = title
    label.font = .systemFont(ofSize: 16, weight: .regular)
    label.textColor = .white
    label.translatesAutoresizingMaskIntoConstraints = false
    button.addSubview(label)
    NSLayoutConstraint.activate([
      button.heightAnchor.constraint(equalToConstant: 55),
      image.leadingAnchor.constraint(equalTo: button.leadingAnchor, constant: 15),
      image.centerYAnchor.constraint(equalTo: button.centerYAnchor),
      image.widthAnchor.constraint(equalToConstant: 21),
      image.heightAnchor.constraint(equalToConstant: 21),
      label.leadingAnchor.constraint(equalTo: image.trailingAnchor, constant: 17),
      label.trailingAnchor.constraint(equalTo: button.trailingAnchor, constant: -12),
      label.centerYAnchor.constraint(equalTo: button.centerYAnchor)
    ])
    return button
  }

  private func makeSeparator() -> UIView {
    let line = UIView()
    line.backgroundColor = UIColor.white.withAlphaComponent(0.12)
    line.heightAnchor.constraint(equalToConstant: 0.7).isActive = true
    return line
  }

  private func makeLargeMenuAction(icon: String, title: String, action: @escaping () -> Void) -> UIView {
    let control = ClosureActionControl(action: action)
    let image = UIImageView(image: UIImage(systemName: icon))
    image.tintColor = .white
    image.contentMode = .scaleAspectFit
    image.translatesAutoresizingMaskIntoConstraints = false
    let label = UILabel()
    label.text = title
    label.font = .systemFont(ofSize: 13, weight: .medium)
    label.textColor = .white
    label.textAlignment = .center
    label.translatesAutoresizingMaskIntoConstraints = false
    control.addSubview(image)
    control.addSubview(label)
    NSLayoutConstraint.activate([
      control.heightAnchor.constraint(equalToConstant: 75),
      image.centerXAnchor.constraint(equalTo: control.centerXAnchor),
      image.topAnchor.constraint(equalTo: control.topAnchor, constant: 12),
      image.widthAnchor.constraint(equalToConstant: 24),
      image.heightAnchor.constraint(equalToConstant: 24),
      label.topAnchor.constraint(equalTo: image.bottomAnchor, constant: 5),
      label.centerXAnchor.constraint(equalTo: control.centerXAnchor),
      label.bottomAnchor.constraint(equalTo: control.bottomAnchor, constant: -7)
    ])
    return control
  }

  private func makeFooterCircle(icon: String) -> UIView {
    let glass = UIVisualEffectView(effect: nil)
    if #available(iOS 26.0, *) {
      let effect = UIGlassEffect(style: .regular)
      effect.isInteractive = true
      glass.effect = effect
    } else {
      glass.effect = UIBlurEffect(style: .systemMaterialDark)
    }
    glass.clipsToBounds = true
    glass.layer.cornerRadius = 26
    let image = UIImageView(image: UIImage(systemName: icon))
    image.tintColor = .white
    image.contentMode = .scaleAspectFit
    image.translatesAutoresizingMaskIntoConstraints = false
    glass.contentView.addSubview(image)
    NSLayoutConstraint.activate([image.centerXAnchor.constraint(equalTo: glass.contentView.centerXAnchor), image.centerYAnchor.constraint(equalTo: glass.contentView.centerYAnchor), image.widthAnchor.constraint(equalToConstant: 22), image.heightAnchor.constraint(equalToConstant: 22)])
    glass.heightAnchor.constraint(equalToConstant: 52).isActive = true
    return glass
  }

  private func makeFooterLetter(_ letter: String, size: CGFloat) -> UIView {
    let label = UILabel()
    label.text = letter
    label.font = .systemFont(ofSize: size, weight: .medium)
    label.textColor = .white
    label.textAlignment = .center
    return label
  }

  @objc private func dismissMenu() { dismiss(animated: true) }
}

private final class ClosureActionControl: UIControl {
  private let action: () -> Void
  init(action: @escaping () -> Void) {
    self.action = action
    super.init(frame: .zero)
    addTarget(self, action: #selector(invoke), for: .touchUpInside)
  }
  required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
  @objc private func invoke() { action() }
}
