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
                        //If you wrap this in an if let block, you'll see that 50% of the time on
                        //the conversation row it's there, and 50% of the time its not. This is because
                        //latest message becomes nil when adding a message.
                        Text("\(convo.latestMessage.person.fullName): \(convo.latestMessage.message)")
                            .font(.subheadline)
                    }
                    .background(Color(convo.color).opacity(0.5))
                })
        }.navigationTitle("Conversations \(model.conversations.count)")
    }
}


struct ConversationsView_Previews: PreviewProvider {
    static var previews: some View {
        ConversationsView()
    }
}
