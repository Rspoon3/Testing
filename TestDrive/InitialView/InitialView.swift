//
//  InitialView.swift
//  TestDrive
//

import SwiftUI
import PhotosUI
import SFSymbols

/// Initial view for selecting photos to rank.
struct InitialView: View {
    let onShowPhotosPicker: () -> Void
    let onShowDocumentPicker: () -> Void

    // MARK: - Body

    var body: some View {
        VStack(spacing: 30) {
            
            Spacer()

            Button {
                onShowPhotosPicker()
            } label: {
                Image(symbol: .photoStack)
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(.secondary)
                    .frame(maxWidth: 200)
            }
            
            Spacer()

            VStack(spacing: 15) {
                Button {
                    onShowPhotosPicker()
                } label: {
                    HStack {
                        Image(symbol: .photoOnRectangleAngled)
                            .foregroundColor(.white)
                        Text("Select from Photos")
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: 300)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
                }

                Button {
                    onShowDocumentPicker()
                } label: {
                    HStack {
                        Image(symbol: .folder)
                            .foregroundColor(.white)
                        Text("Select from Files")
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: 300)
                    .padding()
                    .background(Color.green)
                    .cornerRadius(10)
                }
            }
            .padding(.horizontal)
        }
    }
}

#Preview {
    InitialView(
        onShowPhotosPicker: { },
        onShowDocumentPicker: { }
    )
}
