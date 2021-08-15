//
//  NullStateView.swift
//  Broadcast
//
//  Created by Daniel Eden on 14/08/2021.
//

import SwiftUI

struct NullStateView: View {
  enum ViewType {
    case replies, drafts
  }
  
  var type: ViewType
  
  var imageName: String {
    switch type {
    case .drafts:
      return "doc.on.doc"
    case .replies:
      return "arrowshape.turn.up.left"
    }
  }
  
  var label: String {
    switch type {
    case .drafts:
      return "No Drafts"
    case .replies:
      return "No Replies"
    }
  }
  
    var body: some View {
      VStack {
        Spacer()
        VStack(spacing: 8) {
          Image(systemName: imageName)
            .imageScale(.large)
          Text(label)
        }
        .font(.broadcastTitle2)
        .foregroundColor(.secondary)
        Spacer()
      }
    }
}

struct NullStateView_Previews: PreviewProvider {
    static var previews: some View {
      NullStateView(type: .drafts)
    }
}
