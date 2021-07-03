//
//  EngagementCountersView.swift
//  Broadcast
//
//  Created by Daniel Eden on 03/07/2021.
//

import SwiftUI

struct EngagementCountersView: View {
  var likes: Int = 0
  var retweets: Int = 0
  
  var body: some View {
    HStack {
      Label("\(likes)", systemImage: "heart")
      Label("\(retweets)", systemImage: "repeat")
    }
    .font(.broadcastCaption)
    .foregroundColor(.accentColor)
  }
}

struct EngagementCountersView_Previews: PreviewProvider {
    static var previews: some View {
        EngagementCountersView()
    }
}
