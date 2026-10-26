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
  // Keep the tab overview in this controller's view hierarchy instead of stacking
  // a second modal on top of the browser action-sheet modal.
  private var tabsOverviewController: BrowserTabsOverviewViewController?
  private var isDismissingTabsOverview = false
  
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
    if let tabsOverviewController { return tabsOverviewController }
    return tabViewControllers[safe: currentTabIndex]
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
    guard contentView.addressBars.indices.contains(currentTabIndex) else { return }
    let selectedBar = contentView.addressBars[currentTabIndex]
    if let tab = tabViewControllers[safe: currentTabIndex], tab.hasLoadedUrl,
       let url = tab.currentURL {
      selectedBar.setDisplayedDomain(viewModel.getDomain(from: url))
    } else {
      // A blank tab must never inherit the previous tab's title or URL.
      selectedBar.setDisplayedDomain("")
    }

    selectedBar.setSideButtonsHidden(false)
    selectedBar.isUserInteractionEnabled = true
    leftAddressBar?.setSideButtonsHidden(true)
    leftAddressBar?.isUserInteractionEnabled = false
    rightAddressBar?.setSideButtonsHidden(true)
    rightAddressBar?.isUserInteractionEnabled = false
  }

  func scrollAddressBarToCurrentTab() {
    guard contentView.addressBars.indices.contains(currentTabIndex) else { return }
    view.layoutIfNeeded()
    contentView.layoutIfNeeded()
    contentView.addressBarsScrollView.layoutIfNeeded()
    let bar = contentView.addressBars[currentTabIndex]
    let desiredX = bar.frame.minX
    let maxX = max(0, contentView.addressBarsScrollView.contentSize.width - contentView.addressBarsScrollView.bounds.width)
    let x = min(max(0, desiredX), maxX)
    contentView.addressBarsScrollView.setContentOffset(CGPoint(x: x, y: 0), animated: false)
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
    // Avoid presenting a second menu during an in-flight dismissal/presentation.
    guard isViewLoaded, view.window != nil, presentedViewController == nil else { return }
    let menu = BrowserSafariMenuViewController(isOnWebPage: false)
    menu.onAllTabs = { [weak self] in
      // This callback is invoked from the menu dismissal completion. Present on
      // the next run-loop turn so UIKit can finish unlinking the overFullScreen
      // controller before presenting another modal.
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) { [weak self] in
        self?.presentTabsOverview()
      }
    }
    menu.onNewTab = { [weak self] in self?.createAndSelectNewTab() }
    menu.onBookmarks = { [weak self] in self?.browserToolbarDidTapBookmarks() }
    menu.modalPresentationStyle = .overFullScreen
    menu.modalTransitionStyle = .crossDissolve
    present(menu, animated: true)
  }

  private func presentPageActionsMenu() {
    guard isViewLoaded, view.window != nil, presentedViewController == nil else { return }
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
    scrollAddressBarToCurrentTab()
    contentView.tabsScrollView.setContentOffset(CGPoint(x: CGFloat(index) * (contentView.frame.width + contentView.tabsStackViewSpacing), y: 0), animated: false)
  }

  private func presentTabsOverview() {
    guard isViewLoaded, view.window != nil,
          tabsOverviewController == nil, !isDismissingTabsOverview else { return }

    if tabViewControllers.isEmpty {
      openNewTab(isHidden: false)
      currentTabIndex = max(0, tabViewControllers.count - 1)
      scrollAddressBarToCurrentTab()
    }

    view.layoutIfNeeded()
    let safeSelectedIndex = min(max(0, currentTabIndex), tabViewControllers.count - 1)
    let overview = BrowserTabsOverviewViewController(
      tabs: tabViewControllers,
      selectedIndex: safeSelectedIndex,
      closeOverview: { [weak self] completion in
        self?.dismissTabsOverview(completion: completion)
      },
      onSelect: { [weak self] index in
        guard let self, self.tabViewControllers.indices.contains(index) else { return }
        self.currentTabIndex = index
        self.scrollAddressBarToCurrentTab()
        let pageWidth = self.contentView.frame.width + self.contentView.tabsStackViewSpacing
        self.contentView.tabsScrollView.setContentOffset(CGPoint(x: CGFloat(index) * pageWidth, y: 0), animated: false)
      },
      onNewTab: { [weak self] in self?.createAndSelectNewTab() },
      onSearch: { [weak self] in
        guard let self,
              let addressBar = self.contentView.addressBars[safe: self.currentTabIndex] else { return }
        addressBar.textField.becomeFirstResponder()
      },
      onMenu: { [weak self] in
        DispatchQueue.main.async { [weak self] in
          self?.presentBrowserMenu()
        }
      })

    tabsOverviewController = overview
    addChild(overview)
    overview.view.translatesAutoresizingMaskIntoConstraints = false
    overview.view.alpha = 0
    view.addSubview(overview.view)
    NSLayoutConstraint.activate([
      overview.view.topAnchor.constraint(equalTo: view.topAnchor),
      overview.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      overview.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      overview.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
    ])
    overview.didMove(toParent: self)
    setNeedsStatusBarAppearanceUpdate()
    UIView.animate(withDuration: 0.18) {
      overview.view.alpha = 1
    }
  }

  private func dismissTabsOverview(completion: @escaping () -> Void) {
    guard let overview = tabsOverviewController else {
      completion()
      return
    }
    guard !isDismissingTabsOverview else { return }
    isDismissingTabsOverview = true

    overview.willMove(toParent: nil)
    UIView.animate(withDuration: 0.14, animations: {
      overview.view.alpha = 0
    }, completion: { [weak self] _ in
      overview.view.removeFromSuperview()
      overview.removeFromParent()
      if let self {
        if self.tabsOverviewController === overview {
          self.tabsOverviewController = nil
        }
        self.isDismissingTabsOverview = false
        self.setNeedsStatusBarAppearanceUpdate()
      }
      completion()
    })
  }
}

/// A full-screen Safari-style tab overview. Thumbnail sizing and placement follow
/// the supplied reference: narrow portrait previews, labels underneath, and a
/// compact translucent tab-group control row at the bottom.
private final class BrowserTabsOverviewViewController: UIViewController {
  private let tabs: [BrowserTabViewController]
  private let selectedIndex: Int
  private let closeOverview: (@escaping () -> Void) -> Void
  private let onSelect: (Int) -> Void
  private let onNewTab: () -> Void
  private let onSearch: () -> Void
  private let onMenu: () -> Void
  private let scrollView = UIScrollView()
  private let stack = UIStackView()
  private let gradientLayer = CAGradientLayer()
  private let groupPrivateButton = UIButton(type: .system)
  private let groupStartButton = UIButton(type: .system)
  private var selectedGroupIsStartPage = true

  init(
    tabs: [BrowserTabViewController],
    selectedIndex: Int,
    closeOverview: @escaping (@escaping () -> Void) -> Void,
    onSelect: @escaping (Int) -> Void,
    onNewTab: @escaping () -> Void,
    onSearch: @escaping () -> Void,
    onMenu: @escaping () -> Void
  ) {
    self.tabs = tabs
    self.selectedIndex = selectedIndex
    self.closeOverview = closeOverview
    self.onSelect = onSelect
    self.onNewTab = onNewTab
    self.onSearch = onSearch
    self.onMenu = onMenu
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

  override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

  override func viewDidLoad() {
    super.viewDidLoad()
    overrideUserInterfaceStyle = .dark
    view.backgroundColor = UIColor(red: 0.035, green: 0.04, blue: 0.055, alpha: 1)
    buildBackground()
    buildTopControls()
    buildTabCards()
    buildBottomControls()
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    gradientLayer.frame = view.bounds
  }

  private func buildBackground() {
    gradientLayer.colors = [
      UIColor(red: 0.075, green: 0.09, blue: 0.15, alpha: 1).cgColor,
      UIColor(red: 0.055, green: 0.12, blue: 0.14, alpha: 1).cgColor,
      UIColor(red: 0.045, green: 0.05, blue: 0.065, alpha: 1).cgColor,
      UIColor(red: 0.035, green: 0.04, blue: 0.055, alpha: 1).cgColor
    ]
    gradientLayer.locations = [0, 0.38, 0.72, 1]
    gradientLayer.startPoint = CGPoint(x: 0.05, y: 0)
    gradientLayer.endPoint = CGPoint(x: 0.95, y: 1)
    view.layer.insertSublayer(gradientLayer, at: 0)

    let vignette = UIView()
    vignette.backgroundColor = UIColor.black.withAlphaComponent(0.15)
    vignette.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(vignette)
    NSLayoutConstraint.activate([
      vignette.topAnchor.constraint(equalTo: view.topAnchor),
      vignette.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      vignette.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      vignette.bottomAnchor.constraint(equalTo: view.bottomAnchor)
    ])
  }

  private func buildTopControls() {
    let menu = makeGlassCircle(symbol: "ellipsis", accessibilityLabel: "More actions", action: #selector(menuTapped))
    let search = makeGlassCircle(symbol: "magnifyingglass", accessibilityLabel: "Search tabs", action: #selector(searchTapped))
    view.addSubview(menu)
    view.addSubview(search)
    menu.translatesAutoresizingMaskIntoConstraints = false
    search.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      menu.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 2),
      menu.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
      menu.widthAnchor.constraint(equalToConstant: 54),
      menu.heightAnchor.constraint(equalToConstant: 54),
      search.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 2),
      search.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
      search.widthAnchor.constraint(equalToConstant: 54),
      search.heightAnchor.constraint(equalToConstant: 54)
    ])
  }

  private func makeGlassCircle(symbol: String, accessibilityLabel: String, action: Selector) -> UIView {
    let glass = UIVisualEffectView(effect: nil)
    glass.clipsToBounds = true
    glass.layer.cornerRadius = 27
    glass.layer.cornerCurve = .continuous
    glass.layer.borderWidth = 0.8
    glass.layer.borderColor = UIColor.white.withAlphaComponent(0.11).cgColor
    glass.backgroundColor = UIColor(white: 0.08, alpha: 0.42)
    if #available(iOS 26.0, *) {
      let effect = UIGlassEffect(style: .regular)
      effect.isInteractive = true
      glass.effect = effect
    } else {
      glass.effect = UIBlurEffect(style: .systemUltraThinMaterialDark)
    }
    let button = UIButton(type: .system)
    button.tintColor = UIColor(white: 0.96, alpha: 1)
    button.accessibilityLabel = accessibilityLabel
    button.setImage(UIImage(systemName: symbol), for: .normal)
    button.setPreferredSymbolConfiguration(UIImage.SymbolConfiguration(pointSize: symbol == "ellipsis" ? 21 : 25, weight: .regular), forImageIn: .normal)
    button.addTarget(self, action: action, for: .touchUpInside)
    button.translatesAutoresizingMaskIntoConstraints = false
    glass.contentView.addSubview(button)
    NSLayoutConstraint.activate([
      button.topAnchor.constraint(equalTo: glass.contentView.topAnchor),
      button.leadingAnchor.constraint(equalTo: glass.contentView.leadingAnchor),
      button.trailingAnchor.constraint(equalTo: glass.contentView.trailingAnchor),
      button.bottomAnchor.constraint(equalTo: glass.contentView.bottomAnchor)
    ])
    return glass
  }

  private func buildTabCards() {
    scrollView.showsVerticalScrollIndicator = false
    scrollView.alwaysBounceVertical = true
    scrollView.clipsToBounds = true
    scrollView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(scrollView)

    stack.axis = .vertical
    stack.alignment = .center
    stack.spacing = 34
    stack.translatesAutoresizingMaskIntoConstraints = false
    scrollView.addSubview(stack)
    NSLayoutConstraint.activate([
      scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 75),
      scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -104),
      stack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
      stack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
      stack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
      stack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
      stack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor)
    ])

    for index in tabs.indices {
      stack.addArrangedSubview(makeCard(for: index))
    }
  }

  private func makeCard(for index: Int) -> UIView {
    let tab = tabs[index]
    let item = UIView()
    item.translatesAutoresizingMaskIntoConstraints = false
    item.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, multiplier: 0.67).isActive = true

    let preview = UIView()
    preview.backgroundColor = UIColor(white: 0.075, alpha: 1)
    preview.clipsToBounds = true
    preview.layer.cornerRadius = 28
    preview.layer.cornerCurve = .continuous
    preview.layer.borderWidth = 0.7
    preview.layer.borderColor = UIColor.white.withAlphaComponent(index == selectedIndex ? 0.13 : 0.08).cgColor
    preview.translatesAutoresizingMaskIntoConstraints = false
    item.addSubview(preview)

    // Keep the tab overview independent from WKWebView screenshot APIs.
    // Some iOS/WebKit combinations crash when takeSnapshot is invoked while a
    // modal tab overview is being presented. Use a lightweight native preview
    // instead; selecting a card still returns to the original live WKWebView.
    let previewContent = UIView()
    previewContent.translatesAutoresizingMaskIntoConstraints = false
    previewContent.backgroundColor = UIColor(white: 0.055, alpha: 1)
    preview.addSubview(previewContent)
    NSLayoutConstraint.activate([
      previewContent.topAnchor.constraint(equalTo: preview.topAnchor),
      previewContent.leadingAnchor.constraint(equalTo: preview.leadingAnchor),
      previewContent.trailingAnchor.constraint(equalTo: preview.trailingAnchor),
      previewContent.bottomAnchor.constraint(equalTo: preview.bottomAnchor)
    ])

    let previewHeader = UIView()
    previewHeader.backgroundColor = UIColor.white.withAlphaComponent(0.045)
    previewHeader.translatesAutoresizingMaskIntoConstraints = false
    previewContent.addSubview(previewHeader)

    let dotStack = UIStackView()
    dotStack.axis = .horizontal
    dotStack.spacing = 4
    dotStack.translatesAutoresizingMaskIntoConstraints = false
    for color in [UIColor.systemRed, UIColor.systemYellow, UIColor.systemGreen] {
      let dot = UIView()
      dot.backgroundColor = color.withAlphaComponent(0.72)
      dot.layer.cornerRadius = 2.5
      dot.translatesAutoresizingMaskIntoConstraints = false
      NSLayoutConstraint.activate([dot.widthAnchor.constraint(equalToConstant: 5), dot.heightAnchor.constraint(equalToConstant: 5)])
      dotStack.addArrangedSubview(dot)
    }
    previewHeader.addSubview(dotStack)

    let pageTitle = UILabel()
    let pageHost = tab.hasLoadedUrl ? (tab.currentURL?.host ?? "Webpage") : "Start Page"
    pageTitle.text = pageHost
    pageTitle.font = .systemFont(ofSize: 10, weight: .semibold)
    pageTitle.textColor = UIColor(white: 0.88, alpha: 1)
    pageTitle.lineBreakMode = .byTruncatingTail
    pageTitle.textAlignment = .center
    pageTitle.translatesAutoresizingMaskIntoConstraints = false
    previewContent.addSubview(pageTitle)

    let pageSymbol = UIImageView(image: UIImage(systemName: tab.hasLoadedUrl ? "globe" : "safari.fill"))
    pageSymbol.tintColor = UIColor(white: 0.82, alpha: 1)
    pageSymbol.contentMode = .scaleAspectFit
    pageSymbol.translatesAutoresizingMaskIntoConstraints = false
    previewContent.addSubview(pageSymbol)

    let previewLines = UIStackView()
    previewLines.axis = .vertical
    previewLines.alignment = .leading
    previewLines.spacing = 7
    previewLines.translatesAutoresizingMaskIntoConstraints = false
    previewContent.addSubview(previewLines)
    for i in 0..<6 {
      let line = UIView()
      line.backgroundColor = UIColor.white.withAlphaComponent(i == 0 ? 0.16 : 0.075)
      line.layer.cornerRadius = 2
      line.translatesAutoresizingMaskIntoConstraints = false
      line.heightAnchor.constraint(equalToConstant: i == 0 ? 7 : 4).isActive = true
      previewLines.addArrangedSubview(line)
      line.widthAnchor.constraint(equalTo: previewLines.widthAnchor, multiplier: i == 2 || i == 5 ? 0.62 : 0.9).isActive = true
    }

    NSLayoutConstraint.activate([
      preview.topAnchor.constraint(equalTo: item.topAnchor),
      preview.leadingAnchor.constraint(equalTo: item.leadingAnchor),
      preview.trailingAnchor.constraint(equalTo: item.trailingAnchor),
      preview.heightAnchor.constraint(equalTo: preview.widthAnchor, multiplier: 1.28),
      previewHeader.topAnchor.constraint(equalTo: previewContent.topAnchor),
      previewHeader.leadingAnchor.constraint(equalTo: previewContent.leadingAnchor),
      previewHeader.trailingAnchor.constraint(equalTo: previewContent.trailingAnchor),
      previewHeader.heightAnchor.constraint(equalToConstant: 22),
      dotStack.leadingAnchor.constraint(equalTo: previewHeader.leadingAnchor, constant: 10),
      dotStack.centerYAnchor.constraint(equalTo: previewHeader.centerYAnchor),
      pageTitle.centerXAnchor.constraint(equalTo: previewContent.centerXAnchor),
      pageTitle.topAnchor.constraint(equalTo: previewHeader.bottomAnchor, constant: 12),
      pageTitle.leadingAnchor.constraint(greaterThanOrEqualTo: previewContent.leadingAnchor, constant: 7),
      pageTitle.trailingAnchor.constraint(lessThanOrEqualTo: previewContent.trailingAnchor, constant: -7),
      pageSymbol.centerXAnchor.constraint(equalTo: previewContent.centerXAnchor),
      pageSymbol.topAnchor.constraint(equalTo: pageTitle.bottomAnchor, constant: 15),
      pageSymbol.widthAnchor.constraint(equalToConstant: 24),
      pageSymbol.heightAnchor.constraint(equalToConstant: 24),
      previewLines.topAnchor.constraint(equalTo: pageSymbol.bottomAnchor, constant: 16),
      previewLines.leadingAnchor.constraint(equalTo: previewContent.leadingAnchor, constant: 12),
      previewLines.trailingAnchor.constraint(equalTo: previewContent.trailingAnchor, constant: -12)
    ])

    let star = UIImageView(image: UIImage(systemName: "star.fill"))
    star.tintColor = UIColor(white: 0.68, alpha: 1)
    star.contentMode = .scaleAspectFit
    star.translatesAutoresizingMaskIntoConstraints = false
    let title = UILabel()
    title.text = tab.hasLoadedUrl ? (tab.currentURL?.host ?? "Webpage") : "Start Page"
    title.textColor = UIColor(white: 0.96, alpha: 1)
    title.font = .systemFont(ofSize: 14, weight: .medium)
    title.lineBreakMode = .byTruncatingTail
    let titleRow = UIStackView(arrangedSubviews: [star, title])
    titleRow.axis = .horizontal
    titleRow.alignment = .center
    titleRow.spacing = 9
    titleRow.translatesAutoresizingMaskIntoConstraints = false
    item.addSubview(titleRow)
    NSLayoutConstraint.activate([
      star.widthAnchor.constraint(equalToConstant: 14),
      star.heightAnchor.constraint(equalToConstant: 14),
      titleRow.topAnchor.constraint(equalTo: preview.bottomAnchor, constant: 10),
      titleRow.centerXAnchor.constraint(equalTo: item.centerXAnchor),
      titleRow.bottomAnchor.constraint(equalTo: item.bottomAnchor, constant: -2)
    ])

    let tap = UIControl()
    tap.backgroundColor = .clear
    tap.translatesAutoresizingMaskIntoConstraints = false
    tap.tag = index
    tap.addTarget(self, action: #selector(cardTapped(_:)), for: .touchUpInside)
    item.addSubview(tap)
    NSLayoutConstraint.activate([
      tap.topAnchor.constraint(equalTo: preview.topAnchor),
      tap.leadingAnchor.constraint(equalTo: preview.leadingAnchor),
      tap.trailingAnchor.constraint(equalTo: preview.trailingAnchor),
      tap.bottomAnchor.constraint(equalTo: preview.bottomAnchor)
    ])
    return item
  }

  private func buildBottomControls() {
    let plus = makeGlassCircle(symbol: "plus", accessibilityLabel: "New tab", action: #selector(newTabTapped))
    let confirm = UIButton(type: .system)
    confirm.setImage(UIImage(systemName: "checkmark"), for: .normal)
    confirm.tintColor = .white
    confirm.backgroundColor = UIColor(red: 0.35, green: 0.59, blue: 0.98, alpha: 1)
    confirm.layer.cornerRadius = 28
    confirm.layer.cornerCurve = .continuous
    confirm.layer.borderWidth = 1
    confirm.layer.borderColor = UIColor.white.withAlphaComponent(0.24).cgColor
    confirm.setPreferredSymbolConfiguration(UIImage.SymbolConfiguration(pointSize: 26, weight: .regular), forImageIn: .normal)
    confirm.accessibilityLabel = "Done"
    confirm.addTarget(self, action: #selector(doneTapped), for: .touchUpInside)

    let group = UIView()
    group.backgroundColor = UIColor(white: 0.13, alpha: 0.78)
    group.layer.cornerRadius = 28
    group.layer.cornerCurve = .continuous
    group.layer.borderWidth = 0.6
    group.layer.borderColor = UIColor.white.withAlphaComponent(0.06).cgColor
    group.translatesAutoresizingMaskIntoConstraints = false

    groupPrivateButton.setTitle("Private", for: .normal)
    groupPrivateButton.setTitleColor(UIColor(white: 0.59, alpha: 1), for: .normal)
    groupPrivateButton.titleLabel?.font = .systemFont(ofSize: 15, weight: .medium)
    groupPrivateButton.layer.cornerRadius = 26
    groupPrivateButton.addTarget(self, action: #selector(privateGroupTapped), for: .touchUpInside)

    groupStartButton.setTitle("Start…", for: .normal)
    groupStartButton.setTitleColor(.white, for: .normal)
    groupStartButton.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
    groupStartButton.backgroundColor = UIColor(white: 0.28, alpha: 1)
    groupStartButton.layer.cornerRadius = 26
    groupStartButton.layer.borderWidth = 0.8
    groupStartButton.layer.borderColor = UIColor.white.withAlphaComponent(0.13).cgColor
    groupStartButton.addTarget(self, action: #selector(startGroupTapped), for: .touchUpInside)

    let groupStack = UIStackView(arrangedSubviews: [groupPrivateButton, groupStartButton])
    groupStack.axis = .horizontal
    groupStack.distribution = .fillEqually
    groupStack.spacing = 0
    groupStack.translatesAutoresizingMaskIntoConstraints = false
    group.addSubview(groupStack)
    NSLayoutConstraint.activate([
      groupStack.topAnchor.constraint(equalTo: group.topAnchor, constant: 4),
      groupStack.leadingAnchor.constraint(equalTo: group.leadingAnchor, constant: 4),
      groupStack.trailingAnchor.constraint(equalTo: group.trailingAnchor, constant: -4),
      groupStack.bottomAnchor.constraint(equalTo: group.bottomAnchor, constant: -4)
    ])

    let row = UIStackView(arrangedSubviews: [plus, group, confirm])
    row.axis = .horizontal
    row.alignment = .center
    row.spacing = -2
    row.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(row)
    plus.translatesAutoresizingMaskIntoConstraints = false
    confirm.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      plus.widthAnchor.constraint(equalToConstant: 58),
      plus.heightAnchor.constraint(equalToConstant: 58),
      group.widthAnchor.constraint(equalToConstant: 202),
      group.heightAnchor.constraint(equalToConstant: 58),
      confirm.widthAnchor.constraint(equalToConstant: 58),
      confirm.heightAnchor.constraint(equalToConstant: 58),
      row.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      row.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10)
    ])
    updateGroupSelection()
  }

  private func updateGroupSelection() {
    groupPrivateButton.backgroundColor = selectedGroupIsStartPage ? .clear : UIColor(white: 0.28, alpha: 1)
    groupPrivateButton.setTitleColor(selectedGroupIsStartPage ? UIColor(white: 0.59, alpha: 1) : .white, for: .normal)
    groupPrivateButton.titleLabel?.font = .systemFont(ofSize: 15, weight: selectedGroupIsStartPage ? .medium : .semibold)
    groupStartButton.backgroundColor = selectedGroupIsStartPage ? UIColor(white: 0.28, alpha: 1) : .clear
    groupStartButton.setTitleColor(selectedGroupIsStartPage ? .white : UIColor(white: 0.59, alpha: 1), for: .normal)
    groupStartButton.titleLabel?.font = .systemFont(ofSize: 15, weight: selectedGroupIsStartPage ? .semibold : .medium)
    groupStartButton.layer.borderWidth = selectedGroupIsStartPage ? 0.8 : 0
  }

  @objc private func cardTapped(_ sender: UIControl) {
    let index = sender.tag
    let action = onSelect
    closeOverview { action(index) }
  }

  @objc private func newTabTapped() {
    let action = onNewTab
    closeOverview { action() }
  }

  @objc private func doneTapped() {
    let index = selectedIndex
    let action = onSelect
    closeOverview { action(index) }
  }

  @objc private func searchTapped() {
    let action = onSearch
    closeOverview { action() }
  }

  @objc private func menuTapped() {
    let action = onMenu
    closeOverview { action() }
  }

  @objc private func privateGroupTapped() {
    selectedGroupIsStartPage = false
    updateGroupSelection()
  }

  @objc private func startGroupTapped() {
    selectedGroupIsStartPage = true
    updateGroupSelection()
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
  private var panelBottomConstraint: NSLayoutConstraint?
  private var isClosing = false

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
    let panelHeight: CGFloat = isOnWebPage ? 470 : 260
    let heightConstraint = panel.heightAnchor.constraint(equalToConstant: panelHeight)
    let bottomConstraint = panel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -4)
    panelBottomConstraint = bottomConstraint
    NSLayoutConstraint.activate([
      panel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 11),
      panel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -11),
      bottomConstraint,
      heightConstraint,
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

    // The previous menu occupied nearly the full screen width and height.
    // Scale the entire glass card by 35%, including its rows and typography,
    // while offsetting the layout anchor so it still sits on the bottom edge.
    if !isOnWebPage {
      // Increase the previously reduced menu by 10% (0.65 × 1.10).
      let scale: CGFloat = 0.715
      panelBottomConstraint?.constant = -4 + (panelHeight * (1 - scale) / 2)
      panel.transform = CGAffineTransform(scaleX: scale, y: scale)
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
      guard let self else { return }
      let callback = self.onNewTab
      self.closeMenu { callback?() }
    })
    group.addArrangedSubview(makeSeparator())
    group.addArrangedSubview(makeMenuRow(icon: "hand.raised.fill", title: "New Private Tab") { [weak self] in
      guard let self else { return }
      let callback = self.onNewTab
      self.closeMenu { callback?() }
    })
    rowsStack.addArrangedSubview(group)

    let bottomGroup = makeGroup()
    let footer = UIStackView()
    footer.axis = .horizontal
    footer.distribution = .fillEqually
    footer.alignment = .center
    footer.addArrangedSubview(makeLargeMenuAction(icon: "book.closed.fill", title: "Bookmarks") { [weak self] in
      guard let self else { return }
      let callback = self.onBookmarks
      self.closeMenu { callback?() }
    })
    footer.addArrangedSubview(makeLargeMenuAction(icon: "square.on.square", title: "All Tabs") { [weak self] in
      guard let self else { return }
      let callback = self.onAllTabs
      self.closeMenu { callback?() }
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
        self?.closeMenu()
      })
      if index != items.count - 1 { mainGroup.addArrangedSubview(makeSeparator()) }
    }
    rowsStack.addArrangedSubview(mainGroup)

    rowsStack.addArrangedSubview(makeGroupSingleRow(icon: "arrow.down.circle", title: "Downloads") { [weak self] in
      self?.closeMenu()
    })

    let extensions = makeGroup()
    extensions.addArrangedSubview(makeMenuRow(icon: "puzzlepiece.extension", title: "Manage Extensions") { [weak self] in
      self?.closeMenu()
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

  private func closeMenu(completion: (() -> Void)? = nil) {
    guard !isClosing else { return }
    isClosing = true
    view.isUserInteractionEnabled = false
    dismiss(animated: true, completion: completion)
  }

  @objc private func dismissMenu() { closeMenu() }
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
