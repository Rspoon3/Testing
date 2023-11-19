//
//  ContentView.swift
//  Shared
//
//  Created by Richard Witherspoon on 8/9/20.
//

import SwiftUI

@MainActor
struct ContentView: View {
    @State private var model = ContentViewModel()
    
    var body: some View {
        Form {
            switch model.state {
            case .idle:
                EmptyView()
            case .exporting(let title, let progress), .importing(let title, let progress):
                ProgressView(title, value: progress)
            }
            
            DatePicker("Start Date", selection: $model.startDate)
            
            Button("Export") {
                Task {
                    try? await model.authorize()
                    try? await model.export()
                }
            }
            .padding()
            
            Button("Import") {
                Task {
                    try! await model.authorize()
                    model.importFile.toggle()
                }
            }
            .padding()
        }
        .font(.largeTitle)
        .fileImporter(isPresented: $model.importFile, allowedContentTypes: [.data], allowsMultipleSelection: true) { result in
            switch result {
            case .success(let urls):
                model.importAndSave(from: urls)
            case .failure(let failure):
                print(failure.localizedDescription)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
