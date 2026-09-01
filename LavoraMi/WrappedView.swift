//
//  WrappedView.swift
//  LavoraMi
//
//  Created by Andrea Filice on 01/09/2026.
//

import SwiftUI

struct WrappedView: View {
    let stories: [WrappedStory]

    @Environment(\.dismiss) private var dismiss

    @State private var currentIndex = 0
    @State private var progressFractions: [Double]
    @State private var progressTask: Task<Void, Never>?

    init(stories: [WrappedStory] = WrappedStory.augustStories) {
        self.stories = stories
        _progressFractions = State(initialValue: Array(repeating: 0, count: stories.count))
    }

    var body: some View {
        ZStack(alignment: .top) {
            Color.black.ignoresSafeArea()

            TabView(selection: $currentIndex) {
                ForEach(stories) { story in
                    StoryPageView(
                        story: story,
                        isActive: currentIndex == story.id,
                        onDurationReady: handleDurationReady
                    )
                    .tag(story.id)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .onChange(of: currentIndex) { oldValue, newValue in
                handleStoryChanged(from: oldValue, to: newValue)
            }

            progressBar
                .padding(.top, 12)
                .padding(.top, 35) // equivalente al layout_marginTop="35dp" della XML

            // Zone premibili avanti/indietro, stesso rapporto 1:2 della XML
            // (tapPrevious layout_weight="1", tapNext layout_weight="2").
            GeometryReader { geo in
                HStack(spacing: 0) {
                    Color.clear
                        .contentShape(Rectangle())
                        .frame(width: geo.size.width / 3)
                        .onTapGesture { goToStory(currentIndex - 1) }

                    Color.clear
                        .contentShape(Rectangle())
                        .frame(width: geo.size.width * 2 / 3)
                        .onTapGesture { goToStory(currentIndex + 1) }
                }
            }
            .ignoresSafeArea()
        }
        .statusBarHidden()
        .onAppear {
            #if DEBUG
            WrappedStory.debugPrintBundleVideos()
            #endif
        }
        .onDisappear { progressTask?.cancel() }
    }

    private var progressBar: some View {
        HStack(spacing: 4) {
            ForEach(stories.indices, id: \.self) { index in
                GeometryReader { barGeo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.white.opacity(0.35))
                        Capsule()
                            .fill(Color.white)
                            .frame(width: barGeo.size.width * progressFractions[index])
                    }
                }
                .frame(height: 3)
            }
        }
        .padding(.horizontal, 8)
    }

    /// Equivalente a onStoryChanged(position) in WrappedActivity.java.
    private func handleStoryChanged(from oldIndex: Int, to newIndex: Int) {
        for i in 0..<newIndex { progressFractions[i] = 1 }
        for i in (newIndex + 1)..<stories.count { progressFractions[i] = 0 }

        progressTask?.cancel()
        progressTask = nil
        progressFractions[newIndex] = 0
    }

    /// Equivalente a onVideoDurationReady(durationMs) in WrappedActivity.java:
    /// avvia il timer della progress bar solo se la storia è ancora quella attiva.
    private func handleDurationReady(for storyId: Int, duration: Double) {
        guard storyId == currentIndex else { return }
        startProgressAnimation(duration: duration, index: storyId)
    }

    /// Equivalente a startStoryTimer(position, durationMs).
    private func startProgressAnimation(duration: Double, index: Int) {
        progressTask?.cancel()
        progressFractions[index] = 0

        progressTask = Task { @MainActor in
            withAnimation(.linear(duration: duration)) {
                progressFractions[index] = 1
            }
            try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
            guard !Task.isCancelled else { return }
            advanceOrFinish(from: index)
        }
    }

    private func advanceOrFinish(from index: Int) {
        let next = index + 1
        if next < stories.count {
            goToStory(next)
        } else {
            dismiss()
        }
    }

    /// Equivalente a goToStory(index) in WrappedActivity.java.
    private func goToStory(_ index: Int) {
        if index < 0 { return }
        if index >= stories.count {
            dismiss()
            return
        }
        withAnimation { currentIndex = index }
    }
}

#Preview {
    WrappedView()
}
