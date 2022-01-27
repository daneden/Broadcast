//
//  RepliesListView.swift
//  Broadcast
//
//  Created by Daniel Eden on 01/08/2021.
//

import SwiftUI
import Twift

struct RepliesListView: View {
  @Environment(\.presentationMode) var presentationMode
  var tweet: Tweet?
  @State var replies: [Tweet] = []
  
  var body: some View {
    NavigationView {
      NullStateView(type: .replies)
        .navigationTitle("Replies")
        .toolbar {
          Button("Close") {
            presentationMode.wrappedValue.dismiss()
          }
        }
    }
  }
}

struct RepliesListView_Previews: PreviewProvider {
  static var previews: some View {
    RepliesListView()
  }
}
