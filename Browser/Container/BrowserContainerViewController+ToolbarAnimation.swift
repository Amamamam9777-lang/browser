import UIKit

extension BrowserContainerViewController {
  // Keep the back, address and menu capsules on one baseline. The old toolbar
  // animation moved only the address field vertically, creating the overlapping
  // double-pill shown in the supplied screenshots.
  func setupCollapsingToolbarAnimator() {
    collapsingToolbarAnimator = nil
    isCollapsed = false
  }

  func reverseCollapsingToolbarAnimation() {
    isCollapsed = false
  }

  func setupExpandingToolbarAnimator() {
    expandingToolbarAnimator = nil
    isCollapsed = false
  }

  func reverseExpandingToolbarAnimation() {
    isCollapsed = false
  }

  func setAddressBarContainersAlpha(_ alpha: CGFloat) {
    contentView.addressBars.forEach { $0.containerView.alpha = alpha }
  }
}

extension BrowserContainerViewController: BrowserTabViewControllerDelegate {
  func tabViewControllerDidScroll(yOffsetChange: CGFloat) {
    // Intentionally keep the toolbar at a stable baseline like the compact
    // floating Safari toolbar. Do not independently translate its centre capsule.
  }

  func tabViewControllerDidEndDragging() {
    collapsingToolbarAnimator = nil
    expandingToolbarAnimator = nil
  }

  func tabViewController(_ tabViewController: BrowserTabViewController, didStartLoadingURL url: URL) {
    guard let tabIndex = tabViewControllers.firstIndex(where: { $0 == tabViewController }),
          let addressBar = contentView.addressBars[safe: tabIndex] else { return }
    addressBar.setLoadingProgress(0, animated: false)
    addressBar.setDisplayedDomain(viewModel.getDomain(from: url))
  }

  func tabViewController(_ tabViewController: BrowserTabViewController, didChangeLoadingProgressTo progress: Float) {
    guard let tabIndex = tabViewControllers.firstIndex(where: { $0 == tabViewController }) else { return }
    contentView.addressBars[safe: tabIndex]?.setLoadingProgress(progress, animated: true)
  }
}
