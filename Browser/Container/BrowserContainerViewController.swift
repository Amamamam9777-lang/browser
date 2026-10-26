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
    currentAddressBar.domainLabel.text = viewModel.getDomain(from: url)
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

  func addressBarDidTapReload() {
    guard let tab = tabViewControllers[safe: currentTabIndex], tab.hasLoadedUrl else { return }
    tab.reloadWebsite()
  }
  
  func addressBar(_ addressBar: BrowserAddressBar, didReturnWithText text: String) {
    let tabViewController = tabViewControllers[currentTabIndex]
    let isLastTab = currentTabIndex == tabViewControllers.count - 1
    if isLastTab && !tabViewController.hasLoadedUrl {
      // if we started loading a URL and it is on the last tab then ->
      // open a hidden tab so that we can prepare it for new tab animation if the user swipes to the left
      openNewTab(isHidden: true)
    }
    if let url = self.viewModel.getURL(for: text) {
      addressBar.domainLabel.text = viewModel.getDomain(from: url)
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
    let overview = BrowserTabsOverviewViewController(
      tabs: tabViewControllers,
      selectedIndex: currentTabIndex,
      onSelect: { [weak self] index in
        guard let self, index >= 0, index < self.tabViewControllers.count else { return }
        self.currentTabIndex = index
        self.contentView.addressBarsScrollView.setContentOffset(CGPoint(x: CGFloat(index) * self.contentView.addressBarPageWidth, y: 0), animated: false)
        self.contentView.tabsScrollView.setContentOffset(CGPoint(x: CGFloat(index) * self.contentView.frame.width, y: 0), animated: false)
      },
      onNewTab: { [weak self] in
        guard let self else { return }
        self.openNewTab(isHidden: false)
        let index = self.tabViewControllers.count - 1
        self.currentTabIndex = index
        self.contentView.addressBarsScrollView.setContentOffset(CGPoint(x: CGFloat(index) * self.contentView.addressBarPageWidth, y: 0), animated: false)
        self.contentView.tabsScrollView.setContentOffset(CGPoint(x: CGFloat(index) * self.contentView.frame.width, y: 0), animated: false)
      })
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
    config.title = "＋  New Tab"
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
    card.backgroundColor = .secondarySystemBackground
    card.layer.cornerRadius = 20
    card.layer.cornerCurve = .continuous
    card.layer.borderWidth = index == selectedIndex ? 2 : 0.5
    card.layer.borderColor = (index == selectedIndex ? UIColor.systemBlue : UIColor.separator).cgColor
    card.clipsToBounds = true

    let preview = UIView()
    preview.backgroundColor = UIColor { $0.userInterfaceStyle == .dark ? UIColor(white: 0.12, alpha: 1) : UIColor(white: 1, alpha: 1) }
    preview.translatesAutoresizingMaskIntoConstraints = false
    card.addSubview(preview)
    NSLayoutConstraint.activate([preview.topAnchor.constraint(equalTo: card.topAnchor), preview.leadingAnchor.constraint(equalTo: card.leadingAnchor), preview.trailingAnchor.constraint(equalTo: card.trailingAnchor), preview.heightAnchor.constraint(equalToConstant: 150)])
    if let snapshot = tab.view.snapshotView(afterScreenUpdates: false) {
      snapshot.translatesAutoresizingMaskIntoConstraints = false
      snapshot.isUserInteractionEnabled = false
      preview.addSubview(snapshot)
      NSLayoutConstraint.activate([snapshot.topAnchor.constraint(equalTo: preview.topAnchor), snapshot.leadingAnchor.constraint(equalTo: preview.leadingAnchor), snapshot.trailingAnchor.constraint(equalTo: preview.trailingAnchor), snapshot.bottomAnchor.constraint(equalTo: preview.bottomAnchor)])
    } else {
      let globe = UIImageView(image: UIImage(systemName: "globe"))
      globe.tintColor = .tertiaryLabel
      globe.contentMode = .scaleAspectFit
      globe.translatesAutoresizingMaskIntoConstraints = false
      preview.addSubview(globe)
      NSLayoutConstraint.activate([globe.centerXAnchor.constraint(equalTo: preview.centerXAnchor), globe.centerYAnchor.constraint(equalTo: preview.centerYAnchor), globe.widthAnchor.constraint(equalToConstant: 42), globe.heightAnchor.constraint(equalToConstant: 42)])
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
    labels.spacing = 3
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

