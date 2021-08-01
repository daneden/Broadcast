//
//  TweetView.swift
//  Broadcast
//
//  Created by Daniel Eden on 01/08/2021.
//

import SwiftUI

struct TweetView: View {
  @ScaledMetric private var avatarSize: CGFloat = 40
  @ScaledMetric private var padding: CGFloat = 4
  var tweet: TwitterClient.Tweet
  
  var formatter: RelativeDateTimeFormatter {
    let formatter = RelativeDateTimeFormatter()
    formatter.dateTimeStyle = .named
    formatter.unitsStyle = .short
    formatter.formattingContext = .standalone
    
    return formatter
  }
  
  var body: some View {
    HStack(alignment: .top) {
      if let imageUrl = tweet.author?.profileImageURL {
        RemoteImage(url: imageUrl, placeholder: { ProgressView() })
          .aspectRatio(contentMode: .fill)
          .frame(width: avatarSize, height: avatarSize)
          .cornerRadius(36)
      }
      
      VStack(alignment: .leading) {
        HStack {
          if let tweetAuthorName = tweet.author?.name {
            Text(tweetAuthorName).font(.headline)
          }
          
          Group {
            if let tweetAuthorScreenName = tweet.author?.screenName {
              Text("@\(tweetAuthorScreenName)")
            }
            
            if let date = tweet.date {
              Text("• \(formatter.localizedString(for: date, relativeTo: Date()))")
            }
          }.foregroundColor(.secondary)
        }
        
        if let tweetText = tweet.text {
          Text(tweetText)
        }
      }
    }.padding(.vertical, padding)
  }
}

struct TweetView_Previews: PreviewProvider {
  static var previews: some View {
    TweetView(tweet: TwitterClient.Tweet.mockTweet)
  }
}
