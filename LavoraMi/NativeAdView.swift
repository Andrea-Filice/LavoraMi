//
//  NativeAdView.swift
//  LavoraMi
//
//  Created by Andrea Filice on 30/06/2026.
//

import SwiftUI
import GoogleMobileAds

struct NativeAdView: UIViewControllerRepresentable {
    let nativeAd: NativeAd
    
    func makeUIViewController(context: Context) -> UIViewController {
        let controller = UIViewController()
        let adView = createAdView(nativeAd: nativeAd)
        controller.view.addSubview(adView)
        adView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            adView.topAnchor.constraint(equalTo: controller.view.topAnchor),
            adView.bottomAnchor.constraint(equalTo: controller.view.bottomAnchor),
            adView.leadingAnchor.constraint(equalTo: controller.view.leadingAnchor),
            adView.trailingAnchor.constraint(equalTo: controller.view.trailingAnchor)
        ])
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
    
    private func createAdView(nativeAd: NativeAd) -> GoogleMobileAds.NativeAdView {
        let adView = GoogleMobileAds.NativeAdView()
        adView.backgroundColor = .clear
        adView.layer.cornerRadius = 16
        adView.clipsToBounds = true
        
        let cardView = UIView()
        cardView.backgroundColor = UIColor(Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1) : UIColor.white }))
        cardView.layer.cornerRadius = 16
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowOpacity = 0.1
        cardView.layer.shadowOffset = CGSize(width: 0, height: 2)
        cardView.layer.shadowRadius = 4
        adView.addSubview(cardView)
        
        cardView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: adView.topAnchor, constant: 12),
            cardView.bottomAnchor.constraint(equalTo: adView.bottomAnchor, constant: -12),
            cardView.leadingAnchor.constraint(equalTo: adView.leadingAnchor, constant: 12),
            cardView.trailingAnchor.constraint(equalTo: adView.trailingAnchor, constant: -12)
        ])
        
        let contentStack = UIStackView()
        contentStack.axis = .vertical
        contentStack.spacing = 12
        contentStack.layoutMargins = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        contentStack.isLayoutMarginsRelativeArrangement = true
        cardView.addSubview(contentStack)
        
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: cardView.topAnchor),
            contentStack.bottomAnchor.constraint(equalTo: cardView.bottomAnchor),
            contentStack.leadingAnchor.constraint(equalTo: cardView.leadingAnchor),
            contentStack.trailingAnchor.constraint(equalTo: cardView.trailingAnchor)
        ])
        
        let headerStack = UIStackView()
        headerStack.axis = .horizontal
        headerStack.spacing = 12
        headerStack.alignment = .top
        
        let iconView = UIImageView(image: nativeAd.icon?.image)
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.widthAnchor.constraint(equalToConstant: 40).isActive = true
        iconView.heightAnchor.constraint(equalToConstant: 40).isActive = true
        iconView.layer.cornerRadius = 8
        iconView.clipsToBounds = true
        headerStack.addArrangedSubview(iconView)
        
        let titleStack = UIStackView()
        titleStack.axis = .vertical
        titleStack.spacing = 4
        
        let headlineLabel = UILabel()
        headlineLabel.text = nativeAd.headline
        headlineLabel.font = UIFont.systemFont(ofSize: 13, weight: .bold)
        headlineLabel.textColor = UIColor { $0.userInterfaceStyle == .dark ? UIColor.white : UIColor.black }
        headlineLabel.numberOfLines = 1
        titleStack.addArrangedSubview(headlineLabel)
        
        let adBadge = UILabel()
        adBadge.text = "AD"
        adBadge.font = UIFont.systemFont(ofSize: 11, weight: .bold)
        adBadge.textColor = UIColor.gray
        adBadge.numberOfLines = 1
        
        headerStack.addArrangedSubview(titleStack)
        headerStack.addArrangedSubview(adBadge)
        contentStack.addArrangedSubview(headerStack)
        
        let bodyLabel = UILabel()
        bodyLabel.text = nativeAd.body
        bodyLabel.font = UIFont.systemFont(ofSize: 14)
        bodyLabel.textColor = UIColor { $0.userInterfaceStyle == .dark ? UIColor.lightGray : UIColor.darkGray }
        bodyLabel.numberOfLines = 2
        bodyLabel.lineBreakMode = .byTruncatingTail
        bodyLabel.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        bodyLabel.setContentHuggingPriority(.defaultLow, for: .vertical)
        contentStack.addArrangedSubview(bodyLabel)
        
        let ctaButton = UIButton(type: .system)
        ctaButton.setTitle(nativeAd.callToAction ?? String(localized: .installa), for: .normal)
        ctaButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        ctaButton.backgroundColor = UIColor.red
        ctaButton.setTitleColor(.white, for: .normal)
        ctaButton.layer.cornerRadius = 6
        ctaButton.clipsToBounds = true
        ctaButton.contentEdgeInsets = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
        ctaButton.isUserInteractionEnabled = false
        
        let buttonContainer = UIView()
        buttonContainer.addSubview(ctaButton)
        ctaButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            ctaButton.trailingAnchor.constraint(equalTo: buttonContainer.trailingAnchor),
            ctaButton.topAnchor.constraint(equalTo: buttonContainer.topAnchor),
            ctaButton.bottomAnchor.constraint(equalTo: buttonContainer.bottomAnchor),
            ctaButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 80),
            ctaButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 36)
        ])
        buttonContainer.heightAnchor.constraint(equalToConstant: 44).isActive = true
        
        contentStack.addArrangedSubview(buttonContainer)
        
        adView.heightAnchor.constraint(greaterThanOrEqualToConstant: 140).isActive = true
        
        adView.iconView = iconView
        adView.headlineView = headlineLabel
        adView.bodyView = bodyLabel
        adView.callToActionView = ctaButton
        
        adView.nativeAd = nativeAd
        
        return adView
    }
}

struct CompactNativeAdView: UIViewControllerRepresentable {
    let nativeAd: NativeAd

    func makeUIViewController(context: Context) -> UIViewController {
        let controller = UIViewController()
        let adView = createCompactAdView(nativeAd: nativeAd)
        controller.view.addSubview(adView)
        adView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            adView.topAnchor.constraint(equalTo: controller.view.topAnchor),
            adView.bottomAnchor.constraint(equalTo: controller.view.bottomAnchor),
            adView.leadingAnchor.constraint(equalTo: controller.view.leadingAnchor),
            adView.trailingAnchor.constraint(equalTo: controller.view.trailingAnchor)
        ])
        return controller
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}

    private func createCompactAdView(nativeAd: NativeAd) -> GoogleMobileAds.NativeAdView {
        let adView = GoogleMobileAds.NativeAdView()
        adView.backgroundColor = .clear

        let contentStack = UIStackView()
        contentStack.axis = .horizontal
        contentStack.spacing = 12
        contentStack.alignment = .center
        contentStack.layoutMargins = UIEdgeInsets(top: 10, left: 16, bottom: 10, right: 12)
        contentStack.isLayoutMarginsRelativeArrangement = true
        adView.addSubview(contentStack)

        contentStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: adView.topAnchor),
            contentStack.bottomAnchor.constraint(equalTo: adView.bottomAnchor),
            contentStack.leadingAnchor.constraint(equalTo: adView.leadingAnchor),
            contentStack.trailingAnchor.constraint(equalTo: adView.trailingAnchor)
        ])

        let iconView = UIImageView(image: nativeAd.icon?.image)
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.widthAnchor.constraint(equalToConstant: 36).isActive = true
        iconView.heightAnchor.constraint(equalToConstant: 36).isActive = true
        iconView.layer.cornerRadius = 8
        iconView.clipsToBounds = true
        iconView.contentMode = .scaleAspectFit
        contentStack.addArrangedSubview(iconView)

        let titleStack = UIStackView()
        titleStack.axis = .vertical
        titleStack.spacing = 2
        titleStack.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        let headlineLabel = UILabel()
        headlineLabel.text = nativeAd.headline
        headlineLabel.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        headlineLabel.textColor = UIColor { $0.userInterfaceStyle == .dark ? UIColor.white : UIColor.black }
        headlineLabel.numberOfLines = 1
        headlineLabel.lineBreakMode = .byTruncatingTail
        titleStack.addArrangedSubview(headlineLabel)

        let bodyLabel = UILabel()
        bodyLabel.text = nativeAd.body
        bodyLabel.font = UIFont.systemFont(ofSize: 12)
        bodyLabel.textColor = UIColor.gray
        bodyLabel.numberOfLines = 1
        bodyLabel.lineBreakMode = .byTruncatingTail
        titleStack.addArrangedSubview(bodyLabel)

        contentStack.addArrangedSubview(titleStack)

        let ctaButton = UIButton(type: .system)
        ctaButton.setTitle(nativeAd.callToAction ?? String(localized: .installa), for: .normal)
        ctaButton.titleLabel?.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        ctaButton.titleLabel?.adjustsFontSizeToFitWidth = true
        ctaButton.titleLabel?.minimumScaleFactor = 0.8
        ctaButton.backgroundColor = UIColor.red
        ctaButton.setTitleColor(.white, for: .normal)
        ctaButton.layer.cornerRadius = 6
        ctaButton.clipsToBounds = true
        ctaButton.contentEdgeInsets = UIEdgeInsets(top: 6, left: 12, bottom: 6, right: 12)
        ctaButton.isUserInteractionEnabled = false
        ctaButton.setContentHuggingPriority(.required, for: .horizontal)
        ctaButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        contentStack.addArrangedSubview(ctaButton)

        adView.heightAnchor.constraint(greaterThanOrEqualToConstant: 60).isActive = true

        adView.iconView = iconView
        adView.headlineView = headlineLabel
        adView.bodyView = bodyLabel
        adView.callToActionView = ctaButton

        adView.nativeAd = nativeAd

        return adView
    }
}

struct NativeAdPreviewView: View {
    @ObservedObject var adManager: AdMobManager
    
    var body: some View {
        if !adManager.nativeAds.isEmpty {
            NativeAdView(nativeAd: adManager.nativeAds[0])
                .frame(height: 160)
        }
    }
}
