//
//  BroadcastApp.swift
//  Broadcast
//
//  Created by Daniel Eden on 26/06/2021.
//

import SwiftUI

@main
struct BroadcastApp: App {
  @Environment(\.scenePhase) var scenePhase
  @StateObject var themeHelper = ThemeHelper.shared
  @StateObject var twitterClient = TwitterClientManager()
  let persistenceController = PersistanceController.shared
  
  var body: some Scene {
    WindowGroup {
      GeometryReader { geom in
        ZStack(alignment: .top) {
          ContentView()
            .environmentObject(twitterClient)
            .environmentObject(themeHelper)
            .environment(\.managedObjectContext, persistenceController.container.viewContext)
            .accentColor(themeHelper.color)
            .onChange(of: scenePhase) { newPhase in
              persistenceController.save()
            }
          
          Color.clear.background(Material.bar)
            .frame(height: geom.safeAreaInsets.top)
            .ignoresSafeArea(.container, edges: .top)
        }
      }
    }
  }
}
