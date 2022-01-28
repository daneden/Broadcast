//
//  UserView.swift
//  Broadcast
//
//  Created by Daniel Eden on 03/08/2021.
//

import SwiftUI
import Twift

struct UserView: View {
  @ScaledMetric var avatarSize: CGFloat = 24
  
  var user: User
  var body: some View {
    HStack {
      AsyncImage(url: user.profileImageUrl) { image in
        image
          .resizable()
          .aspectRatio(contentMode: .fill)
          .frame(width: avatarSize, height: avatarSize)
          .cornerRadius(36)
      } placeholder: {
        ProgressView()
      }
      
      VStack(alignment: .leading) {
        if let name = user.name {
          Text(name)
            .fontWeight(.bold)
        }
        
        Text("@\(user.username)")
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
