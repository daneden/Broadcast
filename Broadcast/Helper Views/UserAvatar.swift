//
//  UserAvatar.swift
//  Broadcast
//
//  Created by Daniel Eden on 30/01/2022.
//

import SwiftUI

struct UserAvatar: View {
  var avatarUrl: URL?
  @ScaledMetric var size = 36
    var body: some View {
      AsyncImage(url: avatarUrl) { image in
        image
          .resizable()
          .aspectRatio(contentMode: .fill)
          .cornerRadius(size)
          .overlay(Circle().stroke(Color.primary.opacity(0.1), lineWidth: 1))
      } placeholder: {
        ProgressView()
      }
      .background(.regularMaterial)
      .clipShape(Circle())
      .frame(width: size, height: size)
    }
}

struct UserAvatar_Previews: PreviewProvider {
    static var previews: some View {
        UserAvatar()
    }
}
