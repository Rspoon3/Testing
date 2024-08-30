//
//  ContentView.swift
//  Shared
//
//  Created by Richard Witherspoon on 8/9/20.
//

import SwiftUI

struct ContentView: View {
    @Namespace var someNamespace
    @State private var id: String?
    @State private var showDetails = false
    
    var body: some View {
        ZStack {
            ScrollView() {
                VStack {
                    ForEach(0..<10, id: \.self) { i in
                        ScrollView(.horizontal) {
                            HStack {
                                ForEach(0..<10, id: \.self) { j in
                                    Image(i.isMultiple(of: 2) ? "logo" : "Pepsi-logo")
                                        .resizable()
                                        .scaledToFit()
                                        .matchedGeometryEffect(
                                            id: "\(i)-\(j)",
                                            in: someNamespace,
                                            properties: .frame
                                        )
                                        .frame(height: 100)
                                        .onTapGesture {
//                                            id = "\(i)-\(j)"
                                            withAnimation(.linear(duration: 1)) {
                                                showDetails = true
                                            }
                                            
//                                            Task {
//                                                try await Task.sleep(for: .seconds(2))
//                                                showDetails.toggle()
//                                            }
                                        }
                                }
                            }
                        }
                        .zIndex(i == 0 ? 15 : 1)
                    }
                }
            }.zIndex(1)
            
            if showDetails {
                Image("logo")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 250)
                    .onTapGesture {
                        withAnimation(.linear(duration: 1)) {
                            showDetails.toggle()
                        }
                    }
                    .matchedGeometryEffect(
                        id: "0-0",
                        in: someNamespace,
                        properties: .position
                    ).zIndex(2)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}


struct DetailsView: View {
    let someNamespace: Namespace.ID
    let id: String?
    //    @Binding var showDetails: Bool
    
    var body: some View {
        ScrollView {
            VStack {
                Image("logo")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 250)
                    .matchedGeometryEffect(
                        id: id,
                        in: someNamespace
                    )
                //                    .onTapGesture {
                //                        withAnimation(.linear(duration: 1)) { showDetails = false }
                //                    }
                //
                ForEach(0..<10, id: \.self) { i in
                    Color.blue
                        .frame(height: 100)
                }
            }
        }
    }
}
