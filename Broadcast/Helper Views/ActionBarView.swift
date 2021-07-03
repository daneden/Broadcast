//
//  ActionBarView.swift
//  Broadcast
//
//  Created by Daniel Eden on 03/07/2021.
//

import SwiftUI

struct ActionBarView: View {
  @ScaledMetric var barHeight: CGFloat = 80
  @EnvironmentObject var twitterClient: TwitterClient
  @Binding var replying: Bool
  
  @State private var photoPickerIsPresented = false
  @State private var draftsListIsPresented = false
  
  var body: some View {
    TabView {
      publishingActions
        .padding()
        .disabled(twitterClient.state == .busy)
      
      draftingActions
        .padding()
    }
    .frame(height: barHeight)
    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
    .sheet(isPresented: $photoPickerIsPresented) {
      ImagePicker(imageData: $twitterClient.draft.media)
    }
  }
  
  var publishingActions: some View {
    HStack {
      if let replyId = twitterClient.lastTweet?.id {
        Button(action: {
          if replying {
            twitterClient.sendReply(to: replyId)
          } else {
            withAnimation(.springAnimation) { replying = true }
          }
        }) {
          Label("Send Reply", systemImage: "arrowshape.turn.up.left.fill")
            .font(.broadcastHeadline)
            .labelStyle(
              BroadcastLabelStyle(
                appearance: !replying ? .iconOnly : .normal,
                accessibilityLabel: "Send Reply"
              )
            )
        }
        .buttonStyle(
          BroadcastButtonStyle(
            prominence: replying ? .primary : .secondary,
            isFullWidth: replying,
            isLoading: twitterClient.state == .busy && replying
          )
        )
        .disabled(replying && !twitterClient.draft.isValid)
      }
      
      Button(action: {
        if !replying {
          twitterClient.sendTweet()
        } else {
          withAnimation(.springAnimation) { replying = false }
        }
      }) {
        Label("Send Tweet", systemImage: "paperplane.fill")
          .font(.broadcastHeadline)
          .labelStyle(
            BroadcastLabelStyle(
              appearance: replying ? .iconOnly : .normal,
              accessibilityLabel: "Send Tweet"
            )
          )
      }
      .buttonStyle(
        BroadcastButtonStyle(
          prominence: !replying ? .primary : .secondary,
          isFullWidth: !replying,
          isLoading: twitterClient.state == .busy && !replying
        )
      )
      .disabled(!replying && !twitterClient.draft.isValid)
      
      Button(action: {
        photoPickerIsPresented.toggle()
        UIApplication.shared.endEditing()
      }) {
        Label("Add Media", systemImage: "photo.on.rectangle.angled")
          .labelStyle(IconOnlyLabelStyle())
      }
      .buttonStyle(BroadcastButtonStyle(prominence: .tertiary, isFullWidth: false))
    }
  }
  
  var draftingActions: some View {
    HStack {
      Button(action: { twitterClient.saveDraft() }) {
        Label("Save Draft", systemImage: "arrow.down.doc.fill")
      }.buttonStyle(BroadcastButtonStyle(prominence: .primary))
      .disabled(!twitterClient.draft.isValid)
      
      Button(action: { draftsListIsPresented = true }) {
        Label("\(twitterClient.drafts.count) \(draftNoun)", systemImage: "doc.on.doc")
      }.buttonStyle(BroadcastButtonStyle(prominence: .tertiary))
    }
    .sheet(isPresented: $draftsListIsPresented) {
      DraftsListView()
    }
  }
  
  var draftNoun: String {
    twitterClient.drafts.count == 1 ? "Draft" : "Drafts"
  }
}
