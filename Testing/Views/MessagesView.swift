//
//  MessagesView.swift
//  Testing
//
//  Created by Richard Witherspoon on 8/25/20.
//  Copyright © 2020 Richard Witherspoon. All rights reserved.
//

import SwiftUI

struct MessagesView: View{
    @StateObject var model: MessagesModel
    @ObservedObject var conversation: Conversation
    
    init(conversation: Conversation) {
        _model = StateObject(wrappedValue: MessagesModel(conversation: conversation))
        self.conversation = conversation
    }
    
    var body: some View{
        List(model.messages){ message in
            VStack(alignment: .leading){
                Text("ID: \(message.id)")
                Text("Message: \(message.message)")
                Text("Person: \(message.person.firstName)")
            }
        }.navigationTitle("Messages \(model.messages.count)")
        .toolbar(content: {
            ToolbarItem(placement: .navigationBarTrailing){
                Button("Add Messages"){
                    model.addMessage(to: conversation)
                }
            }
        })
    }
}
