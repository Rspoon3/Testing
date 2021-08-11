//
//  MyData.swift
//  Testing
//
//  Created by Richard Witherspoon on 8/11/21.
//

import Foundation


struct MyData: Identifiable{
    let id = UUID()
    let urlString: String
    let dataInfo: String
    let statusCode: Int
}
