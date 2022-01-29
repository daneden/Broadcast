//
//  EngagementCountersView.swift
//  Broadcast
//
//  Created by Daniel Eden on 03/07/2021.
//

import SwiftUI
import Twift

struct EngagementCountersView: View {
  var tweet: Tweet
  
  var repliesString: String {
    let replyCount = tweet.publicMetrics?.replyCount ?? 0
    switch replyCount {
    case 0:
      return "No Replies"
    case 1:
      return "\(replyCount) Reply"
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
