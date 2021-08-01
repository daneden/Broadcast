//
//  RepliesListView.swift
//  Broadcast
//
//  Created by Daniel Eden on 01/08/2021.
//

import SwiftUI

struct RepliesListView: View {
  @Environment(\.presentationMode) var presentationMode
  var tweet: TwitterClient.Tweet?
  
  var body: some View {
    NavigationView {
      List {
        if let tweet = tweet, let replies = tweet.replies {
          ForEach(replies, id: \.id) { reply in
            TweetView(tweet: reply)
              .onTapGesture {
                guard let screenName = reply.author?.screenName,
                      let tweetId = reply.id else { return }
                let url = URL(string: "https://twitter.com/\(screenName)/status/\(tweetId)")
                
                UIApplication.shared.open(url!)
              }
          }
        }
      }.navigationTitle("Replies")
      .toolbar {
        Button("Close") {
          presentationMode.wrappedValue.dismiss()
        }
      }
    }
  }
}

struct RepliesListView_Previews: PreviewProvider {
    static var previews: some View {
        RepliesListView()
    }
}
