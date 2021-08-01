//
//  EngagementCountersView.swift
//  Broadcast
//
//  Created by Daniel Eden on 03/07/2021.
//

import SwiftUI

struct EngagementCountersView: View {
  var tweet: TwitterClient.Tweet
  
  var repliesString: String {
    let replyCount = tweet.replies?.count ?? 0
    switch replyCount {
    case 0:
      return "No replies"
    case 1:
      return "1 Reply"
    default:
      return "\(replyCount) Replies"
    }
  }
  
  var body: some View {
    Label(repliesString, systemImage: "arrowshape.turn.up.left")
      .font(.broadcastCaption)
      .foregroundColor(.accentColor)
  }
}

struct EngagementCountersView_Previews: PreviewProvider {
    static var previews: some View {
      EngagementCountersView(tweet: TwitterClient.Tweet(likes: 420, retweets: 69, replies: []))
    }
}
