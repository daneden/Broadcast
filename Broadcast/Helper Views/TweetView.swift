//
//  TweetView.swift
//  Broadcast
//
//  Created by Daniel Eden on 01/08/2021.
//

import SwiftUI
import Twift

struct TweetView: View {
  @ScaledMetric private var avatarSize: CGFloat = 36
  @ScaledMetric private var padding: CGFloat = 4
  var tweet: Tweet
  var author: User
  
  var formatter: RelativeDateTimeFormatter {
    let formatter = RelativeDateTimeFormatter()
    formatter.dateTimeStyle = .named
    formatter.unitsStyle = .short
    formatter.formattingContext = .standalone
    
    return formatter
  }
  
  var body: some View {
    HStack(alignment: .top) {
      UserAvatar(avatarUrl: author.profileImageUrlLarger)
      
      VStack(alignment: .leading, spacing: 4) {
        HStack {
          if let date = tweet.createdAt {
            Text("\(Text(author.name).fontWeight(.bold).foregroundColor(.primary)) \(Text("@\(author.username)")) • \(date.formatted(.relative(presentation: .named)))")
              .foregroundColor(.secondary)
          }
        }
        .lineLimit(1)
        
        if let tweetText = tweet.text {
          Text(tweetText).lineSpacing(0)
        }
      }
    }
    .font(.broadcastFootnote)
    .padding(.vertical, padding)
  }
}
