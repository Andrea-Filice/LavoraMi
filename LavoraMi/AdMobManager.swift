//
//  AdMobManager.swift
//  LavoraMi
//
//  Created by Andrea Filice on 30/06/2026.
//

import Foundation
import GoogleMobileAds
import SwiftUI
import Combine

class AdMobManager: NSObject, ObservableObject {
    @Published var nativeAds: [NativeAd] = []
    @Published var isLoading = false
    
    private var adLoader: AdLoader?
    private var loadedCount = 0
    private let totalDesired: Int
    private let batchSize: Int
    private var adUnitIDInUse: String = ""
    
    init(totalDesired: Int = 15, batchSize: Int = 5) {
        self.totalDesired = totalDesired
        self.batchSize = batchSize
        super.init()
        initializeMobileAds()
    }
    
    private func initializeMobileAds() {
        MobileAds.shared.start()
    }
    
    func loadNativeAds(adUnitID: String) {
        guard ConsentManager.shared.canRequestAds else {
            isLoading = false
            return
        }
        
        isLoading = true
        loadedCount = 0
        adUnitIDInUse = adUnitID
        nativeAds.removeAll()
        loadNextBatch()
    }
    
    private func loadNextBatch() {
        if loadedCount >= totalDesired {
            isLoading = false
            return
        }
        
        let remaining = totalDesired - loadedCount
        let toLoad = min(batchSize, remaining)
        
        let imageOptions = NativeAdImageAdLoaderOptions()
        imageOptions.shouldRequestMultipleImages = false
        
        var loaderOptions: [GADAdLoaderOptions] = [imageOptions]
        
        if toLoad > 1 {
            let multipleAdsOptions = MultipleAdsAdLoaderOptions()
            multipleAdsOptions.numberOfAds = toLoad
            loaderOptions.append(multipleAdsOptions)
        }
        
        adLoader = AdLoader(
            adUnitID: adUnitIDInUse,
            rootViewController: nil,
            adTypes: [.native],
            options: loaderOptions
        )
        
        adLoader?.delegate = self
        let request = Request()
        adLoader?.load(request)
    }
    
    deinit {
        for ad in nativeAds {ad.delegate = nil}
    }
}

extension AdMobManager: AdLoaderDelegate {
    func adLoader(_ adLoader: AdLoader, didFailToReceiveAdWithError error: Error) {}
    
    func adLoaderDidFinishLoading(_ adLoader: AdLoader) {
        DispatchQueue.main.async {
            if self.loadedCount < self.totalDesired {self.loadNextBatch()}
            else {self.isLoading = false}
        }
    }
}

extension AdMobManager: NativeAdLoaderDelegate {
    func adLoader(_ adLoader: AdLoader, didReceive nativeAd: NativeAd) {
        DispatchQueue.main.async {
            self.nativeAds.append(nativeAd)
            self.loadedCount += 1
        }
    }
}
