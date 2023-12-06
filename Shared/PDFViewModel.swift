//
//  PDFViewModel.swift
//  Testing
//
//  Created by Richard Witherspoon on 12/2/23.
//

import SwiftUI

@MainActor
@Observable
final class PDFViewModel {
    let address = """
    3000 Lawrence St #8
    Denver CO 80205
    """
    let phone = "(504) 507-0349"
    let email = "hello@kudoboard.com"
    let url = "https://www.kudoboard.com"
    var date = "November 27, 2023"
    var invoiceNumber = "1996-0417"
    var customerName = "Jesús Reyes"
    var customerEmail = "jesus.reyes@freshbooks.com"
    
    let gridItems: [MyGridItem] = [
        MyGridItem(title: "Item", desc: "Premium Kudoboard"),
        MyGridItem(title: "Description", desc: "Online Appreciation Card"),
        MyGridItem(title: "Tax", desc: "$0.00 USD"),
        MyGridItem(title: "Total", desc: "8.99 USD"),
        MyGridItem(title: "Payment Method", desc: "AMEX - 1038"),
        MyGridItem(title: "Status", desc: "Paid"),
    ]
    
    // MARK: - Public
    
    func render() -> URL {
        let renderer = ImageRenderer(content: PDFView(viewModel: self))
        let url = URL.documentsDirectory.appending(path: "output.pdf")
        
        renderer.render { size, context in
            var mediaBox = CGRect(
                x: 0,
                y: 0,
                width: size.width,
                height: size.height
            )
                        
            guard let pdf = CGContext(url as CFURL, mediaBox: &mediaBox, nil) else {
                return
            }
            
            pdf.beginPDFPage(nil)
            pdf.translateBy(
                x: mediaBox.size.width / 2 - size.width / 2,
                y: mediaBox.size.height / 2 - size.height / 2
            )
            
            context(pdf)
            pdf.endPDFPage()
            pdf.closePDF()
        }
        
        return url
    }

}
