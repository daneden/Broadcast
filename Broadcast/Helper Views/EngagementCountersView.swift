//
//  EngagementCountersView.swift
//  Broadcast
//
//  Created by Daniel Eden on 03/07/2021.
//

import SwiftUI

struct EngagementCountersView: View {
  var tweet: TwitterClient.Tweet
  
  var likes: Int {
    tweet.likes ?? 0
  }
  
  var retweets: Int {
    tweet.retweets ?? 0
  }
  
  var replies: Int {
    tweet.replies?.count ?? 0
  }
  
  var body: some View {
    HStack(spacing: 16) {
      Label("\(replies)", systemImage: "arrowshape.turn.up.left")
      Label("\(retweets)", systemImage: "repeat")
      Label("\(likes)", systemImage: "heart")
    }
    .font(.broadcastCaption)
    .foregroundColor(.accentColor)
  }
}

struct EngagementCountersView_Previews: PreviewProvider {
    static var previews: some View {
      EngagementCountersView(tweet: TwitterClient.Tweet(likes: 420, retweets: 69, replies: []))
    }
}
