//
//  AvatarView.swift
//  Testing
//
//  Created by Ricky on 3/12/25.
//

import SwiftUI
import PhotosUI

struct AvatarView: View {
    @Namespace private var animationNamespace
    @State private var showOptions = true
    @State private var selectedPhoto: UIImage?
    @State private var photosPickerItem: PhotosPickerItem?
    @State private var showPhotoPicker = false
    private let canGenerate = true
    private let avatarInt = Int.random(in: 1...50)
    
    var body: some View {
        VStack {
            ZStack {
                if !showOptions {
                    radialButton(icon: "photo.on.rectangle", angle: 0)
                    radialButton(icon: "wand.and.stars", angle: 0)
                    radialButton(icon: "trash", angle: 0)
                        .foregroundStyle(.red)
                }
                
                Button {
                    withAnimation(.spring) {
                        showOptions.toggle()
                    }
                } label: {
                    ZStack(alignment: .bottomTrailing) {
                        if let selectedPhoto {
                            Image(uiImage: selectedPhoto)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 88, height: 88)
                                .clipShape(Circle())

                        } else {
                            Image("avatar-\(avatarInt)")
                                .resizable()
                                .scaledToFill()
                                .frame(width: 88, height: 88)
                                .clipShape(Circle())
                        }
                        
                        Image("icon.pencil.edit")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                }
                .frame(width: 88 + 10, height: 88 + 10)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.bottom, 20)
                .buttonStyle(.plain)
            }

            if showOptions {
                ZStack {
                    radialButton(icon: "photo.on.rectangle", angle: canGenerate ? -60 : -110) {
                        withAnimation(.spring) {
                            showPhotoPicker = true
                            showOptions = false
                        }
                    }
                    
//                    if canGenerate {
                        radialButton(icon: "wand.and.stars", angle: -120) {
                            withAnimation(.spring) {
                                showOptions = false
                            }
                        }
//                    }
                    
                    radialButton(icon: "trash", angle: canGenerate ? -90 : -70) {
                        withAnimation(.spring) {
                            selectedPhoto = nil
                            showOptions = false
                        }
                    }
                    .foregroundStyle(.red)
                }
            }
        }
        .padding(.bottom, 20)
        .photosPicker(
            isPresented: $showPhotoPicker,
            selection: $photosPickerItem,
            matching: .images
        )
        .task(id: photosPickerItem) {
            await handlePhotoSelection()
        }
    }
    
    @MainActor
    func handlePhotoSelection() async {
        guard
            let imageData = try? await photosPickerItem?.loadTransferable(type: Data.self),
            let loadedImage = UIImage(data: imageData)
        else {
            selectedPhoto = nil
            return
        }
        
        withAnimation(.spring()) {
            selectedPhoto = loadedImage
        }
    }
    
    private func radialButton(icon: String, angle: Double, action: (() -> Void)? = nil) -> some View {
        let radius: CGFloat = -140 // Controls how far buttons are from the avatar
        let xOffset = CGFloat(cos(angle * .pi / 180) * radius)
        let yOffset = CGFloat(sin(angle * .pi / 180) * radius) - 140
        let size: CGFloat = action == nil ? 0 : 30
        
        return Button {
            action?()
        } label: {
            ZStack {
                Circle()
                    .fill(Color.white)
                    .shadow(radius: 4)
                    .matchedGeometryEffect(id: "\(icon)-background", in: animationNamespace)
                    .frame(width: size * 2, height: size * 2)
                
                Image(systemName: icon)
                    .resizable()
                    .scaledToFit()
                    .matchedGeometryEffect(id: "\(icon)-icon", in: animationNamespace)
                    .frame(width: size, height: size)
            }
        }
        .offset(
            x: showOptions ? xOffset : 0,
            y: showOptions ? yOffset : 0
        )
          .opacity(showOptions ? 1 : 0)
          .disabled(action == nil)
      }
}

#Preview {
    AvatarView()
}
