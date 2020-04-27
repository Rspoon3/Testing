//
//  TabBar.swift
//  Testing
//
//  Created by Richard Witherspoon on 4/19/20.
//  Copyright © 2020 Richard Witherspoon. All rights reserved.
//

import SwiftUI

struct TabBar : View {
    
    func tabBarItem(text: String, image: String) -> some View {
        VStack {
            Image(systemName: image)
                .imageScale(.large)
            Text(text)
        }
    }
    
    var body: some View {
        TabView {
            ContentView().tabItem{ self.tabBarItem(text: "Home", image: "house.fill") }
            SplitView().tabItem{ self.tabBarItem(text: "History", image: "calendar") }
        }
    }
}

struct TabBar_Previews: PreviewProvider {
    static var previews: some View {
        TabBar()
    }
}



struct SplitView: UIViewControllerRepresentable {
    func makeUIViewController(context: UIViewControllerRepresentableContext<SplitView>) -> UISplitViewController {
        let split = UISplitViewController()
        split.viewControllers = [UIHostingController(rootView: ContentView()), UIHostingController(rootView: Text("test"))]
        return split
    }

    func updateUIViewController(_ uiViewController: UISplitViewController, context: UIViewControllerRepresentableContext<SplitView>) {
        //
    }
}
