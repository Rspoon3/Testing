//
//  PhotoComparisonView.swift
//  TestDrive
//

import SwiftUI
import SFSymbols

/// Displays two photos side by side for comparison and selection.
///
/// This view presents pairs of photos and allows the user to select their preferred image.
/// The layout can be toggled between horizontal, vertical, and stack orientations, with the preference
/// persisted across app launches.
///
/// ## Layout Preference
/// The `layout` property uses `@State` with manual UserDefaults persistence instead of
/// `@AppStorage` to ensure smooth matched geometry effect animations when toggling between layouts.
/// `@AppStorage` can interfere with SwiftUI's animation system for matched geometry effects.
struct PhotoComparisonView: View {
    @StateObject private var viewModel: PhotoComparisonViewModel

    /// Controls the layout orientation (horizontal, vertical, or stack).
    /// Uses `@State` instead of `@AppStorage` to preserve matched geometry effect animations.
    @State private var layout: ComparisonLayout = .horizontal

    /// In stack mode, controls which photo is on top (true = left, false = right).
    @State private var leftPhotoOnTop = true

    @Namespace private var photoAnimation
    @Environment(\.dismiss) private var dismiss

    /// Controls whether the share sheet is presented.
    @State private var showShareSheet = false

    let onDismiss: () -> Void

    /// UserDefaults key for persisting the layout preference.
    private let layoutPreferenceKey = "PhotoComparisonLayout"

    /// Spacing between photos in both vertical and horizontal layouts.
    private let photoSpacing: CGFloat = 20

    // MARK: - Initializer

    init(photos: [PhotoItem], onDismiss: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: PhotoComparisonViewModel(photos: photos))
        self.onDismiss = onDismiss
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            contentView
                .sensoryFeedback(.increase, trigger: viewModel.progress)
                .sensoryFeedback(.increase, trigger: leftPhotoOnTop)
                .sensoryFeedback(.increase, trigger: layout)
                .sensoryFeedback(trigger: showShareSheet) { _, newValue in
                    newValue ? .increase : nil
                }
                .navigationTitle("Which One?")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        HStack {
                            if viewModel.canUndo {
                                Button {
                                    withAnimation {
                                        viewModel.undoLastComparison()
                                    }
                                } label: {
                                    Image(symbol: .arrowUturnBackward)
                                }
                                .transition(.opacity)
                            }

                            Button {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    cycleLayout()
                                }
                            } label: {
                                Image(symbol: layoutIcon)
                            }
                            .contentTransition(
                                .symbolEffect(.replace.magic(fallback: .replace))
                            )
                        }
                    }

                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            showShareSheet = true
                        } label: {
                            Image(symbol: .squareAndArrowUp)
                        }
                        .disabled(layout == .stack)
                    }
                }
                .sheet(isPresented: $showShareSheet) {
                    if let compositeImage = createCompositeImage() {
                        ShareSheet(items: [compositeImage])
                    }
                }
                .onAppear {
                    loadLayoutPreference()
                    AppRatingUserStoreLive.shared.recordStartedPhotoComparison()
                }
        }
        .fullScreenCover(isPresented: $viewModel.rankingComplete) {
            ResultsView(photos: viewModel.rankedPhotos) {
                onDismiss()
                dismiss()
            }
        }
    }

    // MARK: - Private Views

    @ViewBuilder
    private var contentView: some View {
        if let comparison = viewModel.currentComparison {
            comparisonView(comparison)
        } else {
            ProgressView()
        }
    }

    private func comparisonView(_ comparison: (left: PhotoItem, right: PhotoItem)) -> some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                ProgressView(value: viewModel.progress)
                    .progressViewStyle(.linear)
                    .animation(.easeInOut, value: viewModel.progress)

                Text("\(viewModel.progress.formatted(.percent.precision(.fractionLength(0)))) Complete")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .contentTransition(.numericText(value: viewModel.progress))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
            
            switch layout {
            case .horizontal:
                HStack(spacing: photoSpacing) {
                    photoCard(photo: comparison.left, isLeft: true)
                    photoCard(photo: comparison.right, isLeft: false)
                }
                .padding(.horizontal)

            case .vertical:
                VStack(spacing: photoSpacing) {
                    photoCard(photo: comparison.left, isLeft: true)
                    photoCard(photo: comparison.right, isLeft: false)
                }
                .padding(.horizontal)
                .frame(maxWidth: .infinity)

            case .stack:
                ZStack {
                    if leftPhotoOnTop {
                        stackPhotoCard(photo: comparison.right, isLeft: false)
                            .frame(width: 0, height: 0)
                            .opacity(0)
                            .accessibilityHidden(true)
                        stackPhotoCard(photo: comparison.left, isLeft: true)
                    } else {
                        stackPhotoCard(photo: comparison.left, isLeft: true)
                            .frame(width: 0, height: 0)
                            .opacity(0)
                            .accessibilityHidden(true)
                        stackPhotoCard(photo: comparison.right, isLeft: false)
                    }
                }
                .padding(.horizontal)
            }
            
            Spacer()
        }
        .padding(.vertical)
    }
    
    private func photoCard(photo: PhotoItem, isLeft: Bool) -> some View {
        Image(uiImage: photo.image)
            .resizable()
            .scaledToFit()
            .cornerRadius(12)
            .matchedGeometryEffect(id: isLeft ? "leftPhoto" : "rightPhoto", in: photoAnimation)
            .onTapGesture {
                withAnimation(.spring(response: 0.3)) {
                    viewModel.selectPhoto(isLeft: isLeft)
                }
            }
    }

    private func stackPhotoCard(photo: PhotoItem, isLeft: Bool) -> some View {
        Image(uiImage: photo.image)
            .resizable()
            .scaledToFit()
            .cornerRadius(12)
            .matchedGeometryEffect(id: isLeft ? "leftPhoto" : "rightPhoto", in: photoAnimation)
            .onTapGesture {
                leftPhotoOnTop.toggle()
            }
    }

    // MARK: - Private Helpers

    private var layoutIcon: SFSymbol {
        switch layout {
        case .horizontal:
            return .rectangleSplit1x2
        case .vertical:
            return .rectangleSplit2x1
        case .stack:
            return .squareStack
        }
    }

    private func cycleLayout() {
        let allCases = ComparisonLayout.allCases
        if let currentIndex = allCases.firstIndex(of: layout) {
            let nextIndex = (currentIndex + 1) % allCases.count
            layout = allCases[nextIndex]
            UserDefaults.standard.set(layout.rawValue, forKey: layoutPreferenceKey)
        }
    }

    private func loadLayoutPreference() {
        if let savedLayout = UserDefaults.standard.string(forKey: layoutPreferenceKey),
           let layout = ComparisonLayout(rawValue: savedLayout) {
            self.layout = layout
        }
    }

    /// Creates a composite image of the two current photos based on the layout.
    private func createCompositeImage() -> UIImage? {
        guard let comparison = viewModel.currentComparison else { return nil }

        let leftImage = comparison.left.image
        let rightImage = comparison.right.image

        switch layout {
        case .horizontal:
            return createHorizontalComposite(left: leftImage, right: rightImage)
        case .vertical:
            return createVerticalComposite(top: leftImage, bottom: rightImage)
        case .stack:
            return nil // Stack layout doesn't support sharing
        }
    }

    /// Creates a composite image with two images side by side.
    /// - Parameters:
    ///   - left: The left image.
    ///   - right: The right image.
    /// - Returns: A composite image with both images side by side, or nil if creation fails.
    private func createHorizontalComposite(left: UIImage, right: UIImage) -> UIImage? {
        let targetHeight = max(left.size.height, right.size.height)
        let leftWidth = (left.size.width / left.size.height) * targetHeight
        let rightWidth = (right.size.width / right.size.height) * targetHeight
        let spacing: CGFloat = photoSpacing

        let totalWidth = leftWidth + spacing + rightWidth
        let size = CGSize(width: totalWidth, height: targetHeight)

        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        defer { UIGraphicsEndImageContext() }

        left.draw(in: CGRect(x: 0, y: 0, width: leftWidth, height: targetHeight))
        right.draw(in: CGRect(x: leftWidth + spacing, y: 0, width: rightWidth, height: targetHeight))

        return UIGraphicsGetImageFromCurrentImageContext()
    }

    /// Creates a composite image with two images stacked vertically.
    /// - Parameters:
    ///   - top: The top image.
    ///   - bottom: The bottom image.
    /// - Returns: A composite image with both images stacked vertically, or nil if creation fails.
    private func createVerticalComposite(top: UIImage, bottom: UIImage) -> UIImage? {
        let targetWidth = max(top.size.width, bottom.size.width)
        let topHeight = (top.size.height / top.size.width) * targetWidth
        let bottomHeight = (bottom.size.height / bottom.size.width) * targetWidth
        let spacing: CGFloat = photoSpacing

        let totalHeight = topHeight + spacing + bottomHeight
        let size = CGSize(width: targetWidth, height: totalHeight)

        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        defer { UIGraphicsEndImageContext() }

        top.draw(in: CGRect(x: 0, y: 0, width: targetWidth, height: topHeight))
        bottom.draw(in: CGRect(x: 0, y: topHeight + spacing, width: targetWidth, height: bottomHeight))

        return UIGraphicsGetImageFromCurrentImageContext()
    }
}
