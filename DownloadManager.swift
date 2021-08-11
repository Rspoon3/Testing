//
//  DownloadManager.swift
//  Testing
//
//  Created by Richard Witherspoon on 8/11/21.
//

import Foundation


/// Manager of asynchronous download `Operation` objects

protocol DownloadManagerURlSessionDelegate{
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL)
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64)
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?)
}


/// https://stackoverflow.com/questions/32322386/how-to-download-multiple-files-sequentially-using-nsurlsession-downloadtask-in-s/65286011#65286011
class DownloadManager: NSObject {
    /// Dictionary of operations, keyed by the `taskIdentifier` of the `URLSessionTask`
    fileprivate var operations = [Int: DownloadOperation]()
    
    /// Serial OperationQueue for downloads
    private let queue: OperationQueue
    
    /// Delegate-based `URLSession` for DownloadManager
    private let sessionConfig: URLSessionConfiguration
    lazy var session: URLSession = {
        URLSession(configuration: sessionConfig, delegate: self, delegateQueue: nil)
    }()
    
    /// Forward URLSession Delegates
    var delegate: DownloadManagerURlSessionDelegate?
    
    
    //MARK: Initializer
    init(maxConcurrentOperationCount: Int = 1, queueName: String, sessionConfig: URLSessionConfiguration = .default){
        self.queue = OperationQueue()
        self.queue.name = queueName
        self.queue.maxConcurrentOperationCount = maxConcurrentOperationCount

        self.sessionConfig = sessionConfig
    }
    
    /// Add download
    ///
    /// - parameter URL:  The URL of the file to be downloaded
    ///
    /// - returns:        The DownloadOperation of the operation that was queued
    @discardableResult
    func queueDownload(_ url: URL) -> DownloadOperation {
        let operation = DownloadOperation(session: session, url: url)
        operations[operation.task.taskIdentifier] = operation
        queue.addOperation(operation)
        return operation
    }
    
    /// Cancel all queued operations
    func cancelAll() {
        queue.cancelAllOperations()
    }
}

// MARK: URLSessionDownloadDelegate methods
extension DownloadManager: URLSessionDownloadDelegate {
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        operations[downloadTask.taskIdentifier]?.urlSession(session, downloadTask: downloadTask, didFinishDownloadingTo: location)
        
        delegate?.urlSession(session, downloadTask: downloadTask, didFinishDownloadingTo: location)
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        
        delegate?.urlSession(session, downloadTask: downloadTask, didWriteData: bytesWritten, totalBytesWritten: totalBytesWritten, totalBytesExpectedToWrite: totalBytesExpectedToWrite)
    }
}

// MARK: URLSessionTaskDelegate methods
extension DownloadManager: URLSessionTaskDelegate {
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?)  {
        let key = task.taskIdentifier
        operations[key]?.urlSession(session, task: task, didCompleteWithError: error)
        operations.removeValue(forKey: key)
        
        delegate?.urlSession(session, task: task, didCompleteWithError: error)
    }
}
