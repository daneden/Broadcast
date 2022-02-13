//
//  TwitterClient+MockTweet.swift
//  Broadcast
//
//  Created by Daniel Eden on 01/08/2021.
//

import Foundation
import Twift

extension Tweet {
  static var mockTweet: Tweet {
    let jsonString = """
{
  "id": "0",
"text": "just setting up my twttr",
"createdAt": \(Date().timeIntervalSince1970),
"authorId": "0"
}
"""
    return try! JSONDecoder().decode(Tweet.self, from: jsonString.data(using: .utf8)!)
  }
}

extension User {
  static var mockUser: User {
    let jsonString = """
{
  "id": "0",
"name": "Daniel Eden",
"username": "_dte",
"profileImageUrl": "https://pbs.twimg.com/profile_images/1337359860409790469/javRMXyG_x96.jpg"
}
"""
    return try! JSONDecoder().decode(User.self, from: jsonString.data(using: .utf8)!)
  }
}
