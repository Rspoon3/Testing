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
     echo "📌 Current PR Labels: $CURRENT_LABELS"

     # Check if the label is already applied
     if echo "$CURRENT_LABELS" | grep -q "$LABEL_NAME"; then
       LABEL_EXISTS=true
     else
       LABEL_EXISTS=false
     fi

     # If PR qualifies as "Tiny PR"
     if [ "$ADDITIONS" -lt "$MAX_LINES" ] && [ "$DELETIONS" -lt "$MAX_LINES" ]; then
       if [ "$LABEL_EXISTS" = false ]; then
         echo "✅ PR is small enough, and label is missing. Adding label..."
         gh pr edit ${{ github.event.pull_request.number }} --add-label "$LABEL_NAME"
         echo "✅ Label '$LABEL_NAME' added successfully!"
       else
         echo "ℹ️ Label '$LABEL_NAME' is already applied. No action needed."
       fi
     else
       if [ "$LABEL_EXISTS" = true ]; then
         echo "🚫 PR is too large. Removing label..."
         gh pr edit ${{ github.event.pull_request.number }} --remove-label "$LABEL_NAME"
         echo "✅ Label '$LABEL_NAME' removed."
       fi
     fi
   env:
     GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
     ADDITIONS: ${{ env.ADDITIONS }}
     DELETIONS: ${{ env.DELETIONS }}
 - name: Manage Tiny PR Label
   run: |
     echo "🔎 Checking if PR meets the Tiny PR threshold..."
     echo "📌 MAX_LINES = $MAX_LINES"
     echo "📌 ADDITIONS = $ADDITIONS"
     echo "📌 DELETIONS = $DELETIONS"

     # Fetch current labels on the PR
     CURRENT_LABELS=$(gh pr view ${{ github.event.pull_request.number }} --json labels | jq -r '.labels[].name')
     echo "📌 Current PR Labels: $CURRENT_LABELS"

     # Check if the label is already applied
     if echo "$CURRENT_LABELS" | grep -q "$LABEL_NAME"; then
       LABEL_EXISTS=true
     else
       LABEL_EXISTS=false
     fi

     # If PR qualifies as "Tiny PR"
     if [ "$ADDITIONS" -lt "$MAX_LINES" ] && [ "$DELETIONS" -lt "$MAX_LINES" ]; then
       if [ "$LABEL_EXISTS" = false ]; then
         echo "✅ PR is small enough, and label is missing. Adding label..."
         gh pr edit ${{ github.event.pull_request.number }} --add-label "$LABEL_NAME"
         echo "✅ Label '$LABEL_NAME' added successfully!"
       else
         echo "ℹ️ Label '$LABEL_NAME' is already applied. No action needed."
       fi
     else
       if [ "$LABEL_EXISTS" = true ]; then
         echo "🚫 PR is too large. Removing label..."
         gh pr edit ${{ github.event.pull_request.number }} --remove-label "$LABEL_NAME"
         echo "✅ Label '$LABEL_NAME' removed."
       fi
     fi
   env:
     GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
     ADDITIONS: ${{ env.ADDITIONS }}
     DELETIONS: ${{ env.DELETIONS }}
 - name: Manage Tiny PR Label
   run: |
     echo "🔎 Checking if PR meets the Tiny PR threshold..."
     echo "📌 MAX_LINES = $MAX_LINES"
     echo "📌 ADDITIONS = $ADDITIONS"
     echo "📌 DELETIONS = $DELETIONS"

     # Fetch current labels on the PR
     CURRENT_LABELS=$(gh pr view ${{ github.event.pull_request.number }} --json labels | jq -r '.labels[].name')
     echo "📌 Current PR Labels: $CURRENT_LABELS"

     # Check if the label is already applied
     if echo "$CURRENT_LABELS" | grep -q "$LABEL_NAME"; then
       LABEL_EXISTS=true
     else
       LABEL_EXISTS=false
     fi

     # If PR qualifies as "Tiny PR"
     if [ "$ADDITIONS" -lt "$MAX_LINES" ] && [ "$DELETIONS" -lt "$MAX_LINES" ]; then
       if [ "$LABEL_EXISTS" = false ]; then
         echo "✅ PR is small enough, and label is missing. Adding label..."
         gh pr edit ${{ github.event.pull_request.number }} --add-label "$LABEL_NAME"
         echo "✅ Label '$LABEL_NAME' added successfully!"
       else
         echo "ℹ️ Label '$LABEL_NAME' is already applied. No action needed."
       fi
     else
       if [ "$LABEL_EXISTS" = true ]; then
         echo "🚫 PR is too large. Removing label..."
         gh pr edit ${{ github.event.pull_request.number }} --remove-label "$LABEL_NAME"
         echo "✅ Label '$LABEL_NAME' removed."
       fi
     fi
   env:
     GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
     ADDITIONS: ${{ env.ADDITIONS }}
     DELETIONS: ${{ env.DELETIONS }}
 
\*
