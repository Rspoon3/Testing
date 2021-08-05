//
//  ContentView.swift
//  Shared
//
//  Created by Richard Witherspoon on 8/9/20.
//

import SwiftUI

struct ContentView: View {
    @StateObject var model = ContentViewModel()
    
    var body: some View {
        NavigationView{
            List{
                ForEach(model.data){ data in
                    Section{
                        Text(data.urlString)
                        Text(data.dataInfo)
                        Text("Status Code: \(data.statusCode)")
                            .foregroundColor(data.statusCode == 200 ? .green : .red)
                    }
                }
            }
            .navigationTitle(model.title)
            .listStyle(InsetGroupedListStyle())
            .toolbar {
                ToolbarItemGroup {
                    Button {
                        model.data.removeAll(keepingCapacity: true)
                        model.startLoading()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    
                    Toggle(isOn: $model.firstFour) {
                        Text("First Four")
                    }
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}




class ContentViewModel: NSObject, ObservableObject{
    @Published var data = [MyData]()
    @Published var title = "Loading..."
    @Published var firstFour = false
    let formatter = MeasurementFormatter()
    
    
    let urls = [
        "http://maxaccp-app.abcwua.org/ezmaxmobile/map/downloadgeodatabase.action?jsonParam=%7B%0A%20%20%22geoId%22%20:%20%22WUAINACTIVE%22%0A%7D&token=7BD8X0FWDndJgOtx_2ZP5A%3D%3D",
        "http://maxaccp-app.abcwua.org/ezmaxmobile/map/downloadgeodatabase.action?jsonParam=%7B%0A%20%20%22geoId%22%20:%20%22WATERVALVESPRV%22%0A%7D&token=7BD8X0FWDndJgOtx_2ZP5A%3D%3D",
        "http://maxaccp-app.abcwua.org/ezmaxmobile/map/downloadgeodatabase.action?jsonParam=%7B%0A%20%20%22geoId%22%20:%20%22WUAACTIVE%22%0A%7D&token=7BD8X0FWDndJgOtx_2ZP5A%3D%3D",
        "http://maxaccp-app.abcwua.org/ezmaxmobile/map/downloadgeodatabase.action?jsonParam=%7B%0A%20%20%22geoId%22%20:%20%22WASTEWATER%22%0A%7D&token=7BD8X0FWDndJgOtx_2ZP5A%3D%3D",
        "http://maxaccp-app.abcwua.org/ezmaxmobile/map/downloadgeodatabase.action?jsonParam=%7B%0A%20%20%22geoId%22%20:%20%22SANJUAN%22%0A%7D&token=7BD8X0FWDndJgOtx_2ZP5A%3D%3D",
        "http://maxaccp-app.abcwua.org/ezmaxmobile/map/downloadgeodatabase.action?jsonParam=%7B%0A%20%20%22geoId%22%20:%20%22NONPOTABLE%22%0A%7D&token=7BD8X0FWDndJgOtx_2ZP5A%3D%3D",
        "http://maxaccp-app.abcwua.org/ezmaxmobile/map/downloadgeodatabase.action?jsonParam=%7B%0A%20%20%22geoId%22%20:%20%22PARCELLABELS%22%0A%7D&token=7BD8X0FWDndJgOtx_2ZP5A%3D%3D",
        "http://maxaccp-app.abcwua.org/ezmaxmobile/map/downloadgeodatabase.action?jsonParam=%7B%0A%20%20%22geoId%22%20:%20%22NONWUAACTIVE%22%0A%7D&token=7BD8X0FWDndJgOtx_2ZP5A%3D%3D",
        "http://maxaccp-app.abcwua.org/ezmaxmobile/map/downloadgeodatabase.action?jsonParam=%7B%0A%20%20%22geoId%22%20:%20%22WATERVALVESICV%22%0A%7D&token=7BD8X0FWDndJgOtx_2ZP5A%3D%3D",
        "http://maxaccp-app.abcwua.org/ezmaxmobile/map/downloadgeodatabase.action?jsonParam=%7B%0A%20%20%22geoId%22%20:%20%22NONWUAINACTIVE%22%0A%7D&token=7BD8X0FWDndJgOtx_2ZP5A%3D%3D",
        "http://maxaccp-app.abcwua.org/ezmaxmobile/map/downloadgeodatabase.action?jsonParam=%7B%0A%20%20%22geoId%22%20:%20%22WATERPIPESTRANS%22%0A%7D&token=7BD8X0FWDndJgOtx_2ZP5A%3D%3D",
        "http://maxaccp-app.abcwua.org/ezmaxmobile/map/downloadgeodatabase.action?jsonParam=%7B%0A%20%20%22geoId%22%20:%20%22WATER%22%0A%7D&token=7BD8X0FWDndJgOtx_2ZP5A%3D%3D",
        "http://maxaccp-app.abcwua.org/ezmaxmobile/map/downloadgeodatabase.action?jsonParam=%7B%0A%20%20%22geoId%22%20:%20%22WATERVALVES%22%0A%7D&token=7BD8X0FWDndJgOtx_2ZP5A%3D%3D",
        "http://maxaccp-app.abcwua.org/ezmaxmobile/map/downloadgeodatabase.action?jsonParam=%7B%0A%20%20%22geoId%22%20:%20%22WATERPIPES%22%0A%7D&token=7BD8X0FWDndJgOtx_2ZP5A%3D%3D",
    ].map{URL(string: $0)!}
    
    override init() {
        super.init()
        formatter.unitOptions = .naturalScale
        startLoading()
    }
    
    
    func startLoading(){
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
    
    private func download(_ url: URL,completion:  @escaping ()->Void ){
        let sessionConfig = URLSessionConfiguration.default
        
        
        let session = URLSession(configuration: sessionConfig)
        let request = NSMutableURLRequest(url: url)
        request.httpMethod = "GET"
        
        
//        let task = session.downloadTask(with: request as URLRequest) { [weak self] url, response, error in
//            if let error = error{
//                print("Error: \(error.localizedDescription)")
//                completion()
//                return
//            }
//
//            guard let statusCode = (response as? HTTPURLResponse)?.statusCode else{
//                print("No status code")
//                completion()
//                return
//            }
//
//            let measurement = Measurement(value: 100, unit: UnitInformationStorage.bytes)
//            let dataInfo = self?.formatter.string(from: measurement) ?? "N/A"
//            let formattedURL = url!.absoluteString.removingPercentEncoding ?? "N/A"
//
//            let myData = MyData(urlString: formattedURL, dataInfo: dataInfo, statusCode: statusCode)
//
//            DispatchQueue.main.async{
//                self?.data.append(myData)
//            }
//            print("Status Code: \(statusCode)" + "   " + dataInfo)
//            completion()
//        }
        
        let task = session.dataTask(with: request as URLRequest, completionHandler: {[weak self] (data, response, error) -> Void in
            if let error = error{
                print("Error: \(error.localizedDescription)")
                completion()
                return
            }

            guard let statusCode = (response as? HTTPURLResponse)?.statusCode else{
                print("No status code")
                completion()
                return
            }

            guard let data = data else {
                print("No Data")
                completion()
                return
            }

            let measurement = Measurement(value: Double(data.count), unit: UnitInformationStorage.bytes)
            let dataInfo = self?.formatter.string(from: measurement) ?? "N/A"
            let formattedURL = url.absoluteString.removingPercentEncoding ?? "N/A"

            let myData = MyData(urlString: formattedURL, dataInfo: dataInfo, statusCode: statusCode)

            DispatchQueue.main.async{
                self?.data.append(myData)
            }
            print("Status Code: \(statusCode)" + "   " + dataInfo)
            completion()
        })
        
        task.resume()
    }
}


struct MyData: Identifiable{
    let id = UUID()
    let urlString: String
    let dataInfo: String
    let statusCode: Int
}
