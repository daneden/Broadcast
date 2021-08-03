//
//  UserView.swift
//  Broadcast
//
//  Created by Daniel Eden on 03/08/2021.
//

import SwiftUI

struct UserView: View {
  @ScaledMetric var avatarSize: CGFloat = 24
  
  var user: TwitterClient.User
  var body: some View {
    HStack {
      if let imageUrl = user.profileImageURL {
        RemoteImage(url: imageUrl, placeholder: { ProgressView() })
          .aspectRatio(contentMode: .fill)
          .frame(width: avatarSize, height: avatarSize)
          .cornerRadius(36)
      }
      
      VStack(alignment: .leading) {
        if let name = user.name {
          Text(name)
            .fontWeight(.bold)
        }
        
        Text("@\(user.screenName)")
          .foregroundColor(.secondary)
      }
    }.font(.broadcastFootnote)
  }
}

struct UserView_Previews: PreviewProvider {
  static var previews: some View {
    UserView(user: .mockUser)
  }
}
