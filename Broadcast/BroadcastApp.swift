//
//  BroadcastApp.swift
//  Broadcast
//
//  Created by Daniel Eden on 26/06/2021.
//

import SwiftUI

@main
struct BroadcastApp: App {
  @StateObject var twitterAPI = TwitterAPI()
  
  var body: some Scene {
    WindowGroup {
      ContentView()
        .environmentObject(twitterAPI)
    }
  }
}
