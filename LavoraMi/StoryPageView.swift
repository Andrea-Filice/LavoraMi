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
    let onProgress: (Int, Double) -> Void
    let onFinished: (Int) -> Void

    @StateObject private var playerController: StoryVideoPlayer
    @State private var missingAsset = false

    init(story: WrappedStory, isActive: Bool, onProgress: @escaping (Int, Double) -> Void, onFinished: @escaping (Int) -> Void) {
        self.story = story
        self.isActive = isActive
        self.onProgress = onProgress
        self.onFinished = onFinished

        if let url = story.videoURL {_playerController = StateObject(wrappedValue: StoryVideoPlayer(url: url))}
        else {_playerController = StateObject(wrappedValue: StoryVideoPlayer(url: URL(fileURLWithPath: "/dev/null")))}
    }

    var body: some View {
        ZStack {
            Color.black
            VideoPlayerLayerView(player: playerController.player)
        }
        .ignoresSafeArea()
        .onAppear {
            missingAsset = story.videoURL == nil
            playerController.onFinished = { [story] in onFinished(story.id) }
            if isActive { playerController.playFromStart() }
        }
        .onChange(of: isActive) { _, active in
            if active {playerController.playFromStart()}
            else {playerController.pause()}
        }
        .onChange(of: playerController.progress) { _, newValue in
            guard isActive else { return }
            onProgress(story.id, newValue)
        }
        .onDisappear{
            playerController.pause()
        }
        .overlay {
            if missingAsset {
                VStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                    Text("Si è verificato un problema durante il caricamento del Video. Riprova più tardi.")
                        .multilineTextAlignment(.center)
                        .font(.footnote)
                }
                .foregroundStyle(.white)
                .padding()
            }
        }
    }
}
