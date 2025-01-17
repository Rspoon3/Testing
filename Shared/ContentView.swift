//
//  ContentView.swift
//  Shared
//
//  Created by Richard Witherspoon on 8/9/20.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        Text("Hello, world!!!!!!!abcdefghi")
            .padding()
    }
}


#Preview {
    ContentView()
}

/*
 - name: Manage Tiny PR Label
   run: |
     echo "🔎 Checking if PR meets the Tiny PR threshold..."
     echo "📌 MAX_LINES = $MAX_LINES"
     echo "📌 ADDITIONS = $ADDITIONS"
     echo "📌 DELETIONS = $DELETIONS"

     # Fetch current labels on the PR
     CURRENT_LABELS=$(gh pr view ${{ github.event.pull_request.number }} --json labels | jq -r '.labels[].name')

 
\*
