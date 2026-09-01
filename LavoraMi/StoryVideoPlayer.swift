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
    @Published private(set) var durationSeconds: Double?

    private var statusObserver: NSKeyValueObservation?

    init(url: URL) {
        let item = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: item)
        player.actionAtItemEnd = .pause

        statusObserver = item.observe(\.status, options: [.new]) { [weak self] observedItem, _ in
            guard observedItem.status == .readyToPlay else { return }
            let seconds = observedItem.duration.seconds
            guard seconds.isFinite, seconds > 0 else { return }
            Task { @MainActor in
                self?.durationSeconds = seconds
            }
        }
    }

    func playFromStart() {
        player.seek(to: .zero)
        player.play()
    }

    func pause() {
        player.pause()
    }

    deinit {
        statusObserver?.invalidate()
    }
}

struct VideoPlayerLayerView: UIViewRepresentable {
    let player: AVPlayer

    func makeUIView(context: Context) -> PlayerContainerView {
        let view = PlayerContainerView()
        view.playerLayer.player = player
        view.playerLayer.videoGravity = .resizeAspectFill
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
