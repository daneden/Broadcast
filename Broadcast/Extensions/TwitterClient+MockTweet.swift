//
//  TwitterClient+MockTweet.swift
//  Broadcast
//
//  Created by Daniel Eden on 01/08/2021.
//

import Foundation

extension TwitterClient.Tweet {
  static var mockTweet: TwitterClient.Tweet {
    TwitterClient.Tweet(
      numericId: 0,
      id: "0",
      text: "just setting up my twttr",
      likes: 420,
      retweets: 69,
      date: Date(),
      author: .mockUser
    )
  }
}

extension TwitterClient.User {
  static var mockUser: TwitterClient.User {
    TwitterClient.User(
      id: "0",
      screenName: "_dte",
      profileImageURL: URL(string: "https://pbs.twimg.com/profile_images/1337359860409790469/javRMXyG_x96.jpg")!
    )
  }
}
