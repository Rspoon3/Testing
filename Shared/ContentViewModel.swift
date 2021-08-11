//
//  ContentViewModel.swift
//  Testing
//
//  Created by Richard Witherspoon on 8/11/21.
//

import Foundation
import ZipArchive

class ContentViewModel: NSObject, ObservableObject, URLSessionDownloadDelegate{
    @Published var data = [MyData]()
    @Published var title = "Loading..."
    @Published var firstFour = false
    let formatter = MeasurementFormatter()
    
    let siteBlockURLs = [
        "http:/192.168.1.175/emmtest/map/downloadmaptpk.action?jsonParam=%7B%0A%20%20%22blockid%22%20:%20%2200%22,%0A%20%20%22siteid%22%20:%20%22ABCWUA%22%0A%7D&token=UrFOS5XdnH2caDeYLnhVJb3FnJXWKdCB", //siteBlock 00
        "http:/192.168.1.175/emmtest/map/downloadmaptpk.action?jsonParam=%7B%0A%20%20%22siteid%22%20:%20%22ABCWUA%22,%0A%20%20%22blockid%22%20:%20%2201%22%0A%7D&token=UrFOS5XdnH2caDeYLnhVJb3FnJXWKdCB" //siteBlock 01
    ].map{URL(string: $0)!}
    
    let geoDatabaseUrls = [
        "http:/192.168.1.175/emmtest/map/downloadgeodatabase.action?jsonParam=%7B%0A%20%20%22geoId%22%20:%20%22WUAINACTIVE%22%0A%7D&token=UrFOS5XdnH2caDeYLnhVJb3FnJXWKdCB",
        "http:/192.168.1.175/emmtest/map/downloadgeodatabase.action?jsonParam=%7B%0A%20%20%22geoId%22%20:%20%22WATERVALVESPRV%22%0A%7D&token=UrFOS5XdnH2caDeYLnhVJb3FnJXWKdCB",
        "http:/192.168.1.175/emmtest/map/downloadgeodatabase.action?jsonParam=%7B%0A%20%20%22geoId%22%20:%20%22WUAACTIVE%22%0A%7D&token=UrFOS5XdnH2caDeYLnhVJb3FnJXWKdCB",
        "http:/192.168.1.175/emmtest/map/downloadgeodatabase.action?jsonParam=%7B%0A%20%20%22geoId%22%20:%20%22WASTEWATER%22%0A%7D&token=UrFOS5XdnH2caDeYLnhVJb3FnJXWKdCB",
        "http:/192.168.1.175/emmtest/map/downloadgeodatabase.action?jsonParam=%7B%0A%20%20%22geoId%22%20:%20%22SANJUAN%22%0A%7D&token=UrFOS5XdnH2caDeYLnhVJb3FnJXWKdCB",
        "http:/192.168.1.175/emmtest/map/downloadgeodatabase.action?jsonParam=%7B%0A%20%20%22geoId%22%20:%20%22NONPOTABLE%22%0A%7D&token=UrFOS5XdnH2caDeYLnhVJb3FnJXWKdCB",
        "http:/192.168.1.175/emmtest/map/downloadgeodatabase.action?jsonParam=%7B%0A%20%20%22geoId%22%20:%20%22NONWUAACTIVE%22%0A%7D&token=UrFOS5XdnH2caDeYLnhVJb3FnJXWKdCB",
        "http:/192.168.1.175/emmtest/map/downloadgeodatabase.action?jsonParam=%7B%0A%20%20%22geoId%22%20:%20%22WATERVALVESICV%22%0A%7D&token=UrFOS5XdnH2caDeYLnhVJb3FnJXWKdCB",
        "http:/192.168.1.175/emmtest/map/downloadgeodatabase.action?jsonParam=%7B%0A%20%20%22geoId%22%20:%20%22NONWUAINACTIVE%22%0A%7D&token=UrFOS5XdnH2caDeYLnhVJb3FnJXWKdCB",
        "http:/192.168.1.175/emmtest/map/downloadgeodatabase.action?jsonParam=%7B%0A%20%20%22geoId%22%20:%20%22WATERPIPESTRANS%22%0A%7D&token=UrFOS5XdnH2caDeYLnhVJb3FnJXWKdCB",
        "http:/192.168.1.175/emmtest/map/downloadgeodatabase.action?jsonParam=%7B%0A%20%20%22geoId%22%20:%20%22WATERVALVES%22%0A%7D&token=UrFOS5XdnH2caDeYLnhVJb3FnJXWKdCB",
        "http:/192.168.1.175/emmtest/map/downloadgeodatabase.action?jsonParam=%7B%0A%20%20%22geoId%22%20:%20%22WATERPIPES%22%0A%7D&token=UrFOS5XdnH2caDeYLnhVJb3FnJXWKdCB",
    ].map{URL(string: $0)!}
    
    //MARK: Initializer
    override init() {
        super.init()
        formatter.unitOptions = .naturalScale
        startLoading()
    }
    
    
    //MARK: Helpers
    func startLoading(){
        let urls = siteBlockURLs
        let group = DispatchGroup()
        title = "Loading..."
        
        for url in (firstFour ? Array(urls.prefix(4)) : urls){
            group.enter()
            download(url){
                group.leave()
            }
        }
        
        group.notify(queue: .global()){ [weak self] in
            print("All Downloads Completed")
            
            DispatchQueue.main.async {
                self?.title = "Done (\(self?.data.count ?? 0))"
            }
        }
    }
    
    
    //MARK: Private Helpers
    private func download(_ url: URL,completion:  @escaping ()->Void ){
        let sessionConfig = URLSessionConfiguration.default
        
        
        let session = URLSession(configuration: sessionConfig, delegate: self, delegateQueue: .main)
        let request = NSMutableURLRequest(url: url)
        request.httpMethod = "GET"
        
        let downloadTask = session.downloadTask(with: request as URLRequest)
        downloadTask.resume()
    }
    
    private func moveTempDownloadedFileFor(from location: URL){
        let offlineMapsDirectory  = FileManager.filePathInDocumentsDirectory(fileName: "offlineMapsMock")
        let sitesDirectory        = FileManager.filePathIn(directory: offlineMapsDirectory, fileName: "sites")
        let individualSiteSubDirectory = FileManager.filePathIn(directory: sitesDirectory, fileName: "ABCWUA")
        var unZippedFileName: String!
        var unZippedFileExtension: String!
        
        
        SSZipArchive.unzipFile(atPath: location.path,
                               toDestination: individualSiteSubDirectory.path,
                               overwrite: true,
                               password: nil) { fileName, _, _, _ in
            let components = fileName.components(separatedBy: ".")
            unZippedFileName = components.first
            unZippedFileExtension = components.last
        }
        
        guard let unZippedFileExtension = unZippedFileExtension else { return }
        
        var fileUrl = individualSiteSubDirectory
            .appendingPathComponent(unZippedFileName)
            .appendingPathExtension(unZippedFileExtension)
        
        do{
            var nameValue = URLResourceValues()
            nameValue.name = "\(UUID().uuidString).\(unZippedFileExtension)"
            try fileUrl.setResourceValues(nameValue)
            
            print("File successfully unzipped")
        } catch{
            fatalError(error.localizedDescription)
        }
    }
    
    
    //MARK: URLSessionDownloadDelegate
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let error = error else { return }
        print("Did finish  with error: \(error.localizedDescription)")
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        
        let formattedURL = location.absoluteString.removingPercentEncoding ?? "N/A"
        let myData = MyData(urlString: formattedURL, dataInfo: "NA", statusCode: 200)
        
        DispatchQueue.main.async{
            self.data.append(myData)
        }
        
        moveTempDownloadedFileFor(from: location)
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        let fileSize = 63562916 //63 MB
        let percent = Double(totalBytesWritten) / Double(fileSize)
        
        let f = NumberFormatter()
        f.maximumFractionDigits = 2
        f.numberStyle = .percent
        let formattedPercent = f.string(from: NSNumber(value: percent)) ?? "NA"
        
        print("Toal Bytes Written: \(totalBytesWritten) (\(formattedPercent))")
    }
}
