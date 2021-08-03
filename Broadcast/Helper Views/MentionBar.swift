//
//  MentionBar.swift
//  Broadcast
//
//  Created by Daniel Eden on 03/08/2021.
//

import SwiftUI

struct MentionBar: View {
  var users: [TwitterClient.User]
  var tapHandler: (TwitterClient.User) -> Void = { _ in }
  
  var body: some View {
    ScrollView(.horizontal) {
      HStack {
        ForEach(users, id: \.id) { user in
          UserView(user: user)
            .padding(8)
            .background(VisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial)))
            .cornerRadius(6)
            .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
            .onTapGesture {
              tapHandler(user)
            }
        }
      }.padding(12)
    }
  }
}

struct MentionBar_Previews: PreviewProvider {
    static var previews: some View {
      MentionBar(users: [.mockUser])
    }
}
