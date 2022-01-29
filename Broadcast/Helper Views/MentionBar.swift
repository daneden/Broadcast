//
//  MentionBar.swift
//  Broadcast
//
//  Created by Daniel Eden on 03/08/2021.
//

import SwiftUI
import Twift

struct MentionBar: View {
  var users: [User]
  var tapHandler: (User) -> Void = { _ in }
  
  var body: some View {
    ScrollView(.horizontal) {
      HStack {
        ForEach(users, id: \.id) { user in
          UserView(user: user)
            .padding(8)
            .background(.regularMaterial)
            .cornerRadius(6)
            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 6)
            .onTapGesture {
              tapHandler(user)
            }
        }
      }.padding(12)
    }
    .background(.thinMaterial)
  }
}
