//
//  ConversationsView.swift
//  Testing
//
//  Created by Richard Witherspoon on 8/25/20.
//  Copyright © 2020 Richard Witherspoon. All rights reserved.
//

import SwiftUI

struct ConversationsView: View{
    @StateObject var model = ConversationModel()
    
    var body: some View{
        List(model.conversations){ convo in
            NavigationLink(
                destination: MessagesView(conversation: convo),
                label: {
                    VStack(alignment: .leading){
                        Text("Record id: \(convo.id)")
                            .font(.headline)
                        Text("Description: \(convo.myDescription)")
                            .font(.headline)
                        Text("\(convo.latestMessage.person.fullName): \(convo.latestMessage.message)")
                            .font(.subheadline)
                    }
                })
        }.navigationTitle("Conversations \(model.conversations.count)")
    }
}


struct ConversationsView_Previews: PreviewProvider {
    static var previews: some View {
        ConversationsView()
    }
}
