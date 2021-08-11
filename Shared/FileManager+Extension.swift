//
//  FileManager+Extension.swift
//  Testing
//
//  Created by Richard Witherspoon on 8/11/21.
//

import Foundation


public extension FileManager{
    static var documentsDirectory : URL{
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first! as URL
    }
    
    static func filePathInDocumentsDirectory(fileName: String)->URL{
        return FileManager.documentsDirectory.appendingPathComponent(fileName)
    }
    
    static func filePathIn(directory: URL = documentsDirectory, fileName: String)->URL{
        return directory.appendingPathComponent(fileName)
    }
}
