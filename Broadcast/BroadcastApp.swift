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
  @StateObject var twitterClient = TwitterClient()
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
              if newPhase == .active {
                twitterClient.revalidateAccount()
              }
              
              persistenceController.save()
            }
          
          VisualEffectView(effect: UIBlurEffect(style: .regular))
            .frame(height: geom.safeAreaInsets.top)
            .ignoresSafeArea(.all, edges: .top)
        }
      }
    }
  }
}
