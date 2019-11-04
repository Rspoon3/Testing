//
//  ContentView.swift
//  Testing
//
//  Created by Richard Witherspoon on 8/27/19.
//  Copyright © 2019 Richard Witherspoon. All rights reserved.
//

import SwiftUI
import DeviceKit
import MessageUI

struct ContentView: View {
    let radius : CGFloat = 10
    @State private var move = false
    private let mailComposeDelegate = MailDelegate()
    private let email = "richardwitherspoon3@gmail.com"
    private let twitter = "rspoon_3"

    var body: some View {
        VStack(alignment: .leading, spacing: 40){
            HStack{
                Text("Thank you for reaching out to me. I would love any feedback you have. Bug? I can fix that. Feature request? Sure why not. Let me know.")
                    .multilineTextAlignment(.leading)
                Spacer()
            }
            VStack(alignment: .leading, spacing : 10){
                Button(action: {
                    self.openTwitter()
                }) {
                    Text("@\(twitter)")
                        .font(.headline)
                }
                Button(action: {
                    self.presentMailCompose()
                }) {
                    Text(email)
                        .font(.headline)
                }
                Button(action: {
                    self.openWebsite()
                }) {
                    Text("rsw3.xyz")
                        .font(.headline)
                }
            }
            Spacer()
                .multilineTextAlignment(.leading)
                .padding()
            Spacer()
        }
        .padding()
        .navigationBarTitle("Contact")
    }
}

extension ContentView {
    private class MailDelegate: NSObject, MFMailComposeViewControllerDelegate {
        func mailComposeController(_ controller: MFMailComposeViewController,
                                   didFinishWith result: MFMailComposeResult,
                                   error: Error?) {
            
            controller.dismiss(animated: true)
        }
    }

    private func presentMailCompose() {
        guard MFMailComposeViewController.canSendMail() else {
            return
        }
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        let systemVersion = UIDevice.current.systemVersion
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        let vc = UIApplication.shared.keyWindow?.rootViewController
        let composeVC = MFMailComposeViewController()
        composeVC.mailComposeDelegate = mailComposeDelegate

        composeVC.setToRecipients([email])
        composeVC.setSubject("Body Insights Feedback")
        composeVC.setMessageBody("\n\n\n\n\n\n\n\n\nPhone Model: \(Device.current)\niOS Version: \(systemVersion) \nApp Version: \(version!) \nApp Build: \(appVersion!)", isHTML: false)
        
        vc?.present(composeVC, animated: true)
    }
    
    func openWebsite() {
        if let url = URL(string: "https://rsw3.xyz") {
            UIApplication.shared.open(url)
        }
    }
    
    fileprivate func openTwitter() {
        let appURL = URL(string: "twitter://user?screen_name=\(twitter)")!
        let webURL = URL(string: "https://twitter.com/\(twitter)")!
        
        if UIApplication.shared.canOpenURL(appURL as URL) {
            UIApplication.shared.open(appURL)
        } else {
            UIApplication.shared.open(webURL)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

