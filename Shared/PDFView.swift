//
//  PDFView.swift
//  Testing
//
//  Created by Richard Witherspoon on 12/2/23.
//

import SwiftUI

struct PDFView: View {
    let viewModel: PDFViewModel
    private let width: CGFloat = 841
    private let height: CGFloat = 1189
    
    var body: some View {
        VStack {
            Image("logo")
                .resizable()
                .scaledToFit()
                .frame(width: width / 3)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack {
                Text("Invoice")
                    .font(.largeTitle)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                
                Group {
                    Text(viewModel.address)
                    Text("Phone: \(viewModel.phone)")
                    Text("Email: \(viewModel.email)")
                    Text("Web: \(viewModel.url)")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Text("Date of Issue: \(viewModel.date)")
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding()
            .border(Color.black)
            .padding(.vertical, 40)
            
            HStack {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Invoice Number: ")
                        .bold()
                    + Text(viewModel.invoiceNumber)
                    
                    HStack(alignment: .top, spacing: 0) {
                        HStack(alignment: .top, spacing: 0) {
                            Text("Supplier: ")
                                .bold()
                            Text("3000 Lawrence St #8\nDenver, CO 80205")
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Spacer()
                        
                        VStack(alignment: .leading) {
                            Text("Billed To:")
                                .bold()
                            Text(viewModel.customerName)
                            Text(viewModel.customerEmail)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    Text("Tin Number: ")
                        .bold()
                    + Text("81-1250327")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.bottom, 200)
            
            
            Grid(horizontalSpacing: 1, verticalSpacing: 1) {
                GridRow {
                    ForEach(viewModel.gridItems) { item in
                        Text(item.title)
                            .padding()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(.white)
                    }
                }
                
                GridRow {
                    ForEach(viewModel.gridItems) { item in
                        Text(item.desc)
                            .padding()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(.white)
                    }
                }
            }
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .border(Color.black)
            .background(Color.black)
            
            HStack(spacing: 1) {
                Text("Remaining Balance")
                    .padding()
                    .background(.white)
                
                Text("$0.00 USD")
                    .padding()
                    .background(.white)
            }
            .border(Color.black)
            .background(Color.black)
            .padding(.top, 40)
            .frame(maxWidth: .infinity, alignment: .trailing)
            
            Spacer()
        }
        .frame(width: width, height: height)
        .padding(50)
    }
}

#Preview {
    PDFView(viewModel: .init())
}
