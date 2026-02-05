//
//  ContentView.swift
//  TestDrive
//
//  Created by Ricky Witherspoon on 10/26/25.
//

import SwiftUI
import UniformTypeIdentifiers
import UIKit

struct ContentView: View {
  @State private var seedText = "42"
  @State private var timeText = "6.0"
  @State private var isAnimating = true
  @State private var drops: [MatrixWordDrop] = []
  @State private var showExport = false
  @State private var exportDocument: PNGDocument?

  var body: some View {
    VStack(spacing: 16) {
      MatrixArtView(
        drops: drops,
        timeSeconds: currentTimeSeconds,
        isAnimating: isAnimating
      )
      .aspectRatio(1, contentMode: .fit)
      .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
      .overlay(
        RoundedRectangle(cornerRadius: 16, style: .continuous)
          .stroke(Color.green.opacity(0.25), lineWidth: 1)
      )
      .padding(.horizontal)

      controls
        .padding(.horizontal)
        .padding(.bottom)
    }
    .background(Color.black.ignoresSafeArea())
    .onAppear { rebuildDrops() }
    .fileExporter(
      isPresented: $showExport,
      document: exportDocument,
      contentType: .png,
      defaultFilename: "matrix-icon-1024"
    ) { _ in }
  }

  private var controls: some View {
    VStack(spacing: 12) {
      HStack {
        Text("Seed")
          .frame(width: 60, alignment: .leading)
        TextField("Seed", text: $seedText)
          .textFieldStyle(.roundedBorder)
          .keyboardType(.numberPad)
        Button("Apply Seed") { rebuildDrops() }
          .buttonStyle(.bordered)
      }

      HStack {
        Text("Time")
          .frame(width: 60, alignment: .leading)
        TextField("Seconds", text: $timeText)
          .textFieldStyle(.roundedBorder)
          .keyboardType(.decimalPad)
        Button("Apply Time") { isAnimating = false }
          .buttonStyle(.bordered)
      }

      Toggle("Animate", isOn: $isAnimating)
        .toggleStyle(.switch)

      Button("Export 1024x1024 PNG") {
        exportDocument = PNGDocument(image: exportImage())
        showExport = true
      }
      .buttonStyle(.borderedProminent)
    }
    .foregroundStyle(.green)
  }

  private var currentTimeSeconds: Double {
    if isAnimating { return Date().timeIntervalSinceReferenceDate }
    return Double(timeText) ?? 0
  }

  private func rebuildDrops() {
    let seed = Int(seedText) ?? 42
    drops = MatrixModel.makeDrops(seed: seed, wordList: MatrixModel.defaultWords)
  }

  private func exportImage() -> CGImage? {
    let view = MatrixArtView(
      drops: drops,
      timeSeconds: Double(timeText) ?? 0,
      isAnimating: false
    )
    .frame(width: 1024, height: 1024)
    .background(Color.black)
    let renderer = ImageRenderer(content: view)
    renderer.scale = 1
    renderer.proposedSize = .init(width: 1024, height: 1024)
    return renderer.cgImage
  }
}

struct PNGDocument: FileDocument {
  static var readableContentTypes: [UTType] { [.png] }
  static var writableContentTypes: [UTType] { [.png] }

  var image: CGImage?

  init(image: CGImage?) {
    self.image = image
  }

  init(configuration: ReadConfiguration) throws {
    self.image = nil
  }

  func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
    guard let image else {
      return FileWrapper(regularFileWithContents: Data())
    }
    let uiImage = UIImage(cgImage: image)
    let data = uiImage.pngData() ?? Data()
    return FileWrapper(regularFileWithContents: data)
  }
}

#Preview {
  ContentView()
}
