//
//  BrowserAddressBar.swift
//  Browser
//
//  Created by Amer Hukić on 11. 9. 2021..
//

import UIKit
import SnapKit

protocol BrowserAddressBarDelegate: AnyObject {
  func addressBarDidBeginEditing()
  func addressBarDidTapReload()
  func addressBar(_ addressBar: BrowserAddressBar, didReturnWithText text: String)
}

class BrowserAddressBar: UIView {
  private let progressView = UIProgressView()
  private let glassView = UIVisualEffectView(effect: UIBlurEffect(style: .systemChromeMaterial))
  private var text: String?
  private let textFieldSidePadding = CGFloat(4)
  private var textFieldLeadingConstraint: Constraint?
  private var textFieldTrailingConstraint: Constraint?
  let textField = TextField()
  let domainLabel = UILabel()
  let plusOverlayView = UIView()
  let containerView = UIView()
  var containerViewWidthConstraint: Constraint?
  weak var delegate: BrowserAddressBarDelegate?
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    setupView()
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  func setSideButtonsHidden(_ isHidden: Bool) {
    UIView.animate(withDuration: 0.2) {
      self.textField.leftView?.alpha = isHidden ? 0 : 1
      self.textField.rightView?.alpha = isHidden ? 0 : 1
    }
  }
  
  func setLoadingProgress(_ progress: Float, animated: Bool) {
    progressView.alpha = 1
    animated ? animateProgress(progress) : setProgress(progress)
  }

  func setDisplayedDomain(_ domain: String) {
    text = domain
    domainLabel.text = domain
    textField.text = domain
    textField.activityState = .inactive
  }
}

// MARK: Helper methods
private extension BrowserAddressBar {
  func setupView() {
    if #available(iOS 26.0, *) {
      let effect = UIGlassEffect(style: .regular)
      effect.isInteractive = true
      glassView.effect = effect
    } else {
      glassView.effect = UIBlurEffect(style: .systemChromeMaterial)
    }
    layer.masksToBounds = false
    containerView.layer.masksToBounds = false
    containerView.layer.cornerRadius = 28
    containerView.layer.cornerCurve = .continuous
    containerView.layer.borderWidth = 0.5
    containerView.layer.borderColor = UIColor { traits in
      (traits.userInterfaceStyle == .dark ? UIColor.white : UIColor.black).withAlphaComponent(0.10)
    }.cgColor
    containerView.layer.shadowColor = UIColor.black.cgColor
    containerView.layer.shadowOpacity = 0.22
    containerView.layer.shadowRadius = 12
    containerView.layer.shadowOffset = CGSize(width: 0, height: 3)
    containerView.backgroundColor = .clear
    setupContainerView()
    setupTextField()
    setupProgressView()
    setupDomainLabel()
    setupPlusOverlayView()
  }
  
  func setupContainerView() {
    containerView.addSubview(glassView)
    glassView.clipsToBounds = true
    glassView.layer.cornerRadius = 28
    glassView.layer.cornerCurve = .continuous
    glassView.snp.makeConstraints { $0.edges.equalToSuperview() }
    addSubview(containerView)
    containerView.snp.makeConstraints {
      $0.top.leading.bottom.equalToSuperview()
      containerViewWidthConstraint = $0.width.equalToSuperview().constraint
    }
  }
  
  func setupTextField() {
    textField.delegate = self
    textField.onReload = { [weak self] in self?.delegate?.addressBarDidTapReload() }
    containerView.addSubview(textField)
    textField.snp.makeConstraints {
      $0.height.equalTo(42)
      $0.top.bottom.equalToSuperview().inset(7)
      textFieldLeadingConstraint = $0.leading.equalToSuperview().offset(textFieldSidePadding).constraint
      textFieldTrailingConstraint = $0.trailing.equalToSuperview().offset(-textFieldSidePadding).constraint
    }
  }
  
  func setupProgressView() {
    progressView.alpha = 0
    progressView.progressTintColor = .loadingBarBlue
    progressView.trackTintColor = .clear
    textField.addSubview(progressView)
    progressView.snp.makeConstraints {
      $0.leading.trailing.bottom.equalToSuperview()
      $0.height.equalTo(3)
    }
  }
  
  func setupDomainLabel() {
    domainLabel.textAlignment = .center
    domainLabel.font = .systemFont(ofSize: 15, weight: .medium)
    domainLabel.textColor = UIColor { traits in traits.userInterfaceStyle == .dark ? .white : .darkText }
    addSubview(domainLabel)
    domainLabel.snp.makeConstraints {
      $0.center.equalToSuperview()
      $0.width.equalToSuperview().multipliedBy(0.65)
    }
  }
  
  func setupPlusOverlayView() {
    let imageView = UIImageView(image: UIImage(systemName: "plus"))
    imageView.contentMode = .scaleAspectFit
    plusOverlayView.addSubview(imageView)
    imageView.snp.makeConstraints {
      $0.center.equalToSuperview()
      $0.width.height.equalTo(24)
    }
    
    plusOverlayView.layer.cornerRadius = 22
    plusOverlayView.backgroundColor = UIColor.clear
    plusOverlayView.alpha = 0
    containerView.addSubview(plusOverlayView)
    plusOverlayView.snp.makeConstraints {
      $0.edges.equalTo(textField)
    }
  }

  func showEditingState() {
    containerView.layer.shadowOpacity = 0
    domainLabel.alpha = 0
    textFieldLeadingConstraint?.update(offset: 0)
    textFieldTrailingConstraint?.update(offset: 0)
  }
  
  func showInactiveState() {
    containerView.layer.shadowOpacity = 0.22
    domainLabel.alpha = 1
    textFieldLeadingConstraint?.update(offset: textFieldSidePadding)
    textFieldTrailingConstraint?.update(offset: -textFieldSidePadding)
  }
  
  func setProgressViewProgress(progress: CGFloat, animated: Bool) {
    if animated {
      progressView.setProgress(Float(progress), animated: true)
      return
    }
    
    if let layers = progressView.layer.sublayers {
      layers.forEach { layer in
        layer.removeAllAnimations()
      }
    }
    progressView.setProgress(Float(progress), animated: false)
    progressView.setNeedsLayout()
    progressView.layoutIfNeeded()
  }
  
  func setProgress(_ progress: Float) {
    if let layers = progressView.layer.sublayers {
      layers.forEach { layer in
        layer.removeAllAnimations()
      }
    }
    progressView.setProgress(progress, animated: false)
    progressView.setNeedsLayout()
    progressView.layoutIfNeeded()
  }
  
  func animateProgress(_ progress: Float) {
    if progress < 1 {
      progressView.setProgress(progress, animated: true)
    } else {
      progressView.progress = progress
      UIView.animate(withDuration: 0.5, animations: {
        self.progressView.layoutIfNeeded()
      }, completion: { _ in
        self.setProgress(0)
        UIView.animate(withDuration: 0.2) {
          self.progressView.alpha = 0
        }
      })
    }
  }
}

// MARK: UITextFieldDelegate
extension BrowserAddressBar: UITextFieldDelegate {
  func textFieldDidBeginEditing(_: UITextField) {
    delegate?.addressBarDidBeginEditing()
    textField.text = text
    showEditingState()
    textField.activityState = .editing
  }
  
  func textFieldDidEndEditing(_: UITextField) {
    textField.text = text
    showInactiveState()
    textField.activityState = .inactive
  }
  
  func textFieldShouldReturn(_: UITextField) -> Bool {
    text = textField.text
    showInactiveState()
    delegate?.addressBar(self, didReturnWithText: text ?? "")
    return true
  }
}
