//
//  ContentView2.swift
//  Testing (iOS)
//
//  Created by Richard Witherspoon on 5/28/23.
//

import SwiftUI

struct ContentView2: View {
    let test = ["Author", "Genre", "Pages", "Book Type", "Start Date", "End Date"]
    
    @State private var size: CGSize = .zero
    @StateObject private var canvasViewModel = PKCanvasViewModel()

    var body: some View {
        ZStack(alignment: .top) {
            PKCanvas(viewModel: canvasViewModel)
                .border(Color.green)
            
            Color.blue
                .opacity(0.3)
                .frame(height: 900)
                .alignmentGuide(.top) { _ in
                    -self.size.height - 30
                }
            
            HStack(alignment: .top, spacing: 0) {
                VStack(alignment: .leading, spacing: 30) {
                    Text("Book I")
                        .foregroundColor(.white)
                        .frame(minWidth: 100)
                        .font(.headline)
                        .padding(.all, 8)
                        .background(
                            Capsule()
                                .foregroundColor(.gray)
                        )
                    
                    Image("mockingBird")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 300)
                        .cornerRadius(8)
                    
                    HStack {
                        Image(systemName: "star.fill")
                        Image(systemName: "star.fill")
                        Image(systemName: "star.fill")
                        Image(systemName: "star.fill")
                        Image(systemName: "star.fill")
                    }
                    .font(.title)
                    .symbolRenderingMode(.multicolor)
                }
                .padding()
                .border(Color.red)
                
                VStack(spacing: 10) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Title")
                            .font(.headline)
                        Divider()
                    }
                    
                    LazyVGrid(columns: [.init(), .init()]) {
                        ForEach(test, id: \.self) { item in
                            VStack(alignment: .leading, spacing: 10) {
                                Text(item)
                                    .font(.headline)
                                Divider()
                            }
                        }
                    }
                }
                .readSize { size in
                    self.size = size
                }
            }
        }
    }
}

struct ContentView2_Previews: PreviewProvider {
    static var previews: some View {
        ContentView2()
    }
}


extension VerticalAlignment {
    enum MyVertical: AlignmentID {
        static func defaultValue(in d: ViewDimensions) -> CGFloat {
            d[VerticalAlignment.top]
        }
    }
    static let myAlignment = VerticalAlignment(MyVertical.self)
}

extension View {
  func readSize(onChange: @escaping (CGSize) -> Void) -> some View {
    background(
      GeometryReader { geometryProxy in
        Color.clear
          .preference(key: SizePreferenceKey.self, value: geometryProxy.size)
      }
    )
    .onPreferenceChange(SizePreferenceKey.self, perform: onChange)
  }
}

private struct SizePreferenceKey: PreferenceKey {
  static var defaultValue: CGSize = .zero
  static func reduce(value: inout CGSize, nextValue: () -> CGSize) {}
}
