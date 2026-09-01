//
//  StoryVideoPlayer.swift
//  LavoraMi
//
//  Created by Andrea Filice on 01/09/2026.
//

import SwiftUI
import Combine
import AVFoundation

@MainActor
final class StoryVideoPlayer: ObservableObject {
    let player: AVPlayer
    @Published private(set) var progress: Double = 0
    var onFinished: (() -> Void)?
    private var timeObserverToken: Any?
    private var hasReportedFinish = false

    init(url: URL) {
        let item = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: item)
        player.actionAtItemEnd = .pause
    }

    func playFromStart() {
        hasReportedFinish = false
        progress = 0
        player.seek(to: .zero)
        player.play()
        startObservingProgress()
    }

    func pause() {
        player.pause()
        stopObservingProgress()
    }

    private func startObservingProgress() {
        stopObservingProgress()

        let interval = CMTime(seconds: 1.0 / 60.0, preferredTimescale: 600)
        timeObserverToken = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self, let duration = self.player.currentItem?.duration.seconds,
                  duration.isFinite, duration > 0 else { return }

            let current = time.seconds
            self.progress = min(max(current / duration, 0), 1)

            if current >= duration - 0.05, !self.hasReportedFinish {
                self.hasReportedFinish = true
                self.onFinished?()
            }
        }
    }

    private func stopObservingProgress() {
        if let token = timeObserverToken {
            player.removeTimeObserver(token)
            timeObserverToken = nil
        }
    }

    deinit {
        if let token = timeObserverToken {
            player.removeTimeObserver(token)
        }
    }
}

struct VideoPlayerLayerView: UIViewRepresentable {
    let player: AVPlayer

    func makeUIView(context: Context) -> PlayerContainerView {
        let view = PlayerContainerView()
        view.playerLayer.player = player
        view.playerLayer.videoGravity = .resizeAspect
        return view
    }

    func updateUIView(_ uiView: PlayerContainerView, context: Context) {
        if uiView.playerLayer.player !== player {
            uiView.playerLayer.player = player
        }
    }
}

final class PlayerContainerView: UIView {
    let playerLayer = AVPlayerLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .black
        layer.addSublayer(playerLayer)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) non è supportato")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer.frame = bounds
    }
}
