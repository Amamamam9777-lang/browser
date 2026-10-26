import UIKit

extension BrowserContainerViewController: UIScrollViewDelegate {
  func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
    let page = max(1, contentView.addressBarPageWidth)
    currentTabIndex = min(max(0, Int(round(scrollView.contentOffset.x / page))), max(0, tabViewControllers.count - 1))
  }

  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    let maximumAddressOffset = max(1, scrollView.contentSize.width - scrollView.bounds.width)
    let fraction = min(max(scrollView.contentOffset.x / maximumAddressOffset, 0), 1)
    let maximumTabOffset = max(0, contentView.tabsScrollView.contentSize.width - contentView.tabsScrollView.bounds.width)
    contentView.tabsScrollView.contentOffset.x = maximumTabOffset * fraction
  }

  func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
    let page = max(1, contentView.addressBarPageWidth)
    let pageFraction = targetContentOffset.pointee.x / page
    var nextIndex: Int
    if velocity.x > 0 {
      nextIndex = Int(ceil(pageFraction))
    } else if velocity.x < 0 {
      nextIndex = Int(floor(pageFraction))
    } else {
      nextIndex = Int(round(pageFraction))
    }
    nextIndex = min(max(0, nextIndex), max(0, tabViewControllers.count - 1))
    currentTabIndex = nextIndex
    // Use the arranged view's measured position, not a guessed width. This
    // prevents fractions of the previous tab from remaining visible.
    let targetX = contentView.addressBars[safe: nextIndex]?.frame.minX ?? CGFloat(nextIndex) * page
    targetContentOffset.pointee = CGPoint(x: targetX, y: targetContentOffset.pointee.y)
  }

  func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {}
  func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {}
}
