//
//  LastTweetReplyView.swift
//  Broadcast
//
//  Created by Daniel Eden on 02/07/2021.
//

import SwiftUI

struct LastTweetReplyView: View {
  @ScaledMetric var spacing: CGFloat = 4
  var lastTweet: TwitterClient.Tweet
  var replying: Bool = false
  
  var body: some View {
    HStack(spacing: 0) {
      Label(title: {
        VStack(alignment: .leading, spacing: spacing) {
          Text("Reply\(replying ? "ing" : "") to last tweet")
            .foregroundColor(.accentColor)
          if let tweetText = lastTweet.text {
            Text(tweetText)
              .foregroundColor(.secondary)
          }
        }
      }, icon: {
        Image(systemName: "arrowshape.turn.up.left")
          .foregroundColor(.accentColor)
      })
      .font(.broadcastFootnote)
      
      Spacer(minLength: 0)
    }.fixedSize(horizontal: false, vertical: true)
    .padding(spacing * 2)
    .background(Color.accentColor.opacity(0.1))
    .cornerRadius(spacing * 2)
  }
}

struct LastTweetReplyView_Previews: PreviewProvider {
    static var previews: some View {
      LastTweetReplyView(lastTweet: TwitterClient.Tweet(text: "Example tweet"))
    }
}
