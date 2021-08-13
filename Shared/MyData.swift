//
//  MyData.swift
//  Testing
//
//  Created by Richard Witherspoon on 8/11/21.
//

import Foundation


struct MyData: Identifiable{
    var id: Int { task.taskIdentifier }
    let urlString: String
    let dataInfo: String
    let statusCode: Int
    let task: URLSessionTask
    var downloadProgress:Double = 0
}
