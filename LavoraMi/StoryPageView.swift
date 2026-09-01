//
//  StoryPageView.swift
//  LavoraMi
//
//  Created by Andrea Filice on 01/09/2026.
//

import SwiftUI

struct StoryPageView: View {
    let story: WrappedStory
    let isActive: Bool
    let onDurationReady: (Int, Double) -> Void

    @StateObject private var playerController: StoryVideoPlayer
    @State private var missingAsset = false

    init(story: WrappedStory, isActive: Bool, onDurationReady: @escaping (Int, Double) -> Void) {
        self.story = story
        self.isActive = isActive
        self.onDurationReady = onDurationReady

        if let url = story.videoURL {
            _playerController = StateObject(wrappedValue: StoryVideoPlayer(url: url))
        }
        else {
            _playerController = StateObject(wrappedValue: StoryVideoPlayer(url: URL(fileURLWithPath: "/dev/null")))
        }
    }

    var body: some View {
        ZStack {
            Color.black
            VideoPlayerLayerView(player: playerController.player)
        }
        .ignoresSafeArea()
        .onAppear {
            missingAsset = story.videoURL == nil
            if isActive { playerController.playFromStart() }
        }
        .onChange(of: isActive) { _, active in
            if active {
                playerController.playFromStart()
            } else {
                playerController.pause()
            }
        }
        .onChange(of: playerController.durationSeconds) { _, duration in
            guard isActive, let duration else { return }
            onDurationReady(story.id, duration)
        }
        .overlay {
            if missingAsset {
                VStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                    Text("Video \"\(story.videoResourceName).\(story.videoExtension)\" non trovato nel bundle")
                        .multilineTextAlignment(.center)
                        .font(.footnote)
                }
                .foregroundStyle(.white)
                .padding()
            }
        }
    }
}
