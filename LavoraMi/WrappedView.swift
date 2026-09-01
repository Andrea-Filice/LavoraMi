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
                        onProgress: handleProgress,
                        onFinished: handleFinished
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
                .padding(.top, 35)

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
                    .overlay(
                        Capsule().stroke(Color.black.opacity(0.3), lineWidth: 0.75)
                    )
                    .shadow(color: .black.opacity(0.35), radius: 1.5, x: 0, y: 0.5)
                }
                .frame(height: 3)
            }
        }
        .padding(.horizontal, 8)
    }

    private func handleStoryChanged(from oldIndex: Int, to newIndex: Int) {
        for i in 0..<newIndex { progressFractions[i] = 1 }
        for i in (newIndex + 1)..<stories.count { progressFractions[i] = 0 }
    }

    private func handleProgress(for storyId: Int, progress: Double) {
        guard storyId == currentIndex else { return }
        progressFractions[storyId] = progress
    }
    
    private func handleFinished(for storyId: Int) {
        guard storyId == currentIndex else { return }
        progressFractions[storyId] = 1
        advanceOrFinish(from: storyId)
    }

    private func advanceOrFinish(from index: Int) {
        let next = index + 1
        
        if next < stories.count {goToStory(next)}
        else {dismiss()}
    }

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
