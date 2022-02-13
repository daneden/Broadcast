//
//  RepliesListView.swift
//  Broadcast
//
//  Created by Daniel Eden on 01/08/2021.
//

import SwiftUI
import Twift

struct RepliesListView: View {
  @EnvironmentObject var twitterClient: TwitterClientManager
  @Environment(\.presentationMode) var presentationMode
  var tweet: Tweet?
  @State var replies: [(tweet: Tweet, author: User)] = []
  
  var body: some View {
    NavigationView {
      Group {
        if !replies.isEmpty {
          List(replies, id: \.tweet.id) { reply in
            TweetView(tweet: reply.tweet, author: reply.author)
          }
        } else {
          NullStateView(type: .replies)
        }
      }
        .navigationTitle("Replies")
        .toolbar {
          Button("Close") {
            presentationMode.wrappedValue.dismiss()
          }
        }
    }.task {
      if let tweet = tweet {
        replies = await twitterClient.getReplies(for: tweet.id)
      }
    }
  }
}

struct RepliesListView_Previews: PreviewProvider {
  static var previews: some View {
    RepliesListView()
  }
}
