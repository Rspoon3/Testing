//
//  ContentView.swift
//  Shared
//
//  Created by Richard Witherspoon on 8/9/20.
//

import SwiftUI

struct MyGridItem: Identifiable {
    let id = UUID()
    let title: String
    let desc: String
}

@MainActor
struct ContentView: View {
    @State var viewModel = PDFViewModel()
    private let desiredPDFPreviewHeight: CGFloat = 500
    
    var body: some View {
        NavigationSplitView {
            Form {
                TextField("Date", text: $viewModel.date)
                TextField("Invoice Number", text: $viewModel.invoiceNumber)
                TextField("Customer Name", text: $viewModel.customerName)
                TextField("Customer Email", text: $viewModel.customerEmail)
            }
            .toolbar {
                ShareLink("Export PDF", item: viewModel.render())
            }
        } detail: {
            PDFView(viewModel: viewModel)
                .border(Color.black)
                .scaleEffect(desiredPDFPreviewHeight/1189)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
