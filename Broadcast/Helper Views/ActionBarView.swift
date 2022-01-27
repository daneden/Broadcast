//
//  ActionBarView.swift
//  Broadcast
//
//  Created by Daniel Eden on 03/07/2021.
//

import SwiftUI

struct ActionBarView: View {
  @ScaledMetric var barHeight: CGFloat = 80
  @EnvironmentObject var twitterClient: TwitterClientManager
  @Binding var replying: Bool
  
  @State private var photoPickerIsPresented = false
  
  var body: some View {
    publishingActions
      .disabled(twitterClient.state == .busy)
//      .sheet(isPresented: $photoPickerIsPresented) {
//        ImagePicker(chosenImage: $twitterClient.draft.media)
//      }
  }
  
  var publishingActions: some View {
    HStack {
      if twitterClient.lastTweet != nil {
        Button(action: {
          if replying {
            Task {
              await twitterClient.sendTweet(asReply: true)
            }
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
        .disabled(replying && !twitterClient.draftIsValid())
      }
      
      Button(action: {
        if !replying {
          Task {
            await twitterClient.sendTweet()
          }
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
      .disabled(!replying && !twitterClient.draftIsValid())
      .accessibilityIdentifier("sendTweetButton")
      
      Button(action: {
        photoPickerIsPresented.toggle()
        UIApplication.shared.endEditing()
      }) {
        Label("Add Media", systemImage: "photo.on.rectangle.angled")
          .labelStyle(IconOnlyLabelStyle())
      }
      .buttonStyle(BroadcastButtonStyle(prominence: .tertiary, isFullWidth: false))
      .accessibilityIdentifier("imagePickerButton")
    }
  }
}
