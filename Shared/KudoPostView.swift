//
//  KudoPostView.swift
//  Testing
//
//  Created by Ricky on 3/22/25.
//

import SwiftUI

struct KudoPostView: View {
    @State private var message: String = ""
    @State private var statusMessage: String?
    @State private var isSending = false

    // Inject your configured service (you can pass this from outside too)
    private let service = KudoBoardService(config: KudoBoardConfig(
        boardID: "BDk2ACtk",
        csrfToken: csrfToken,
        cookieHeader: cookieHeader
    ))

    var body: some View {
        VStack(spacing: 16) {
            Text("Send a Kudo")
                .font(.headline)

            TextField("Type your message…", text: $message)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .disabled(isSending)

            Button(action: sendMessage) {
                if isSending {
                    ProgressView()
                } else {
                    Text("Send")
                        .frame(maxWidth: .infinity)
                }
            }
            .disabled(message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSending)
            .buttonStyle(.borderedProminent)

            if let status = statusMessage {
                Text(status)
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding()
        .frame(width: 400)
    }

    private func sendMessage() {
        isSending = true
        statusMessage = nil

        let trimmed = message.trimmingCharacters(in: .whitespacesAndNewlines)

        service.postKudo(message: trimmed) { result in
            DispatchQueue.main.async {
                isSending = false
                switch result {
                case .success:
                    message = ""
                    statusMessage = "✅ Kudo sent!"
                case .failure(let error):
                    statusMessage = "❌ Error: \(error.localizedDescription)"
                }
            }
        }
    }
}
