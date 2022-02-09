//
//  AttachmentDropDelegate.swift
//  Broadcast
//
//  Created by Daniel Eden on 09/02/2022.
//

import Foundation
import SwiftUI

struct AttachmentDropDelegate: DropDelegate {
  @Binding var dropActive: Bool
  @ObservedObject var twitterClient: TwitterClientManager
  
  func dropEntered(info: DropInfo) {
    withAnimation(.springAnimation) {
      if dropActive == false {
        dropActive = true
      }
    }
  }
  
  func dropExited(info: DropInfo) {
    withAnimation(.springAnimation) {
      if dropActive == true {
        dropActive = false
      }
    }
  }
  
  func performDrop(info: DropInfo) -> Bool {
    withAnimation(.springAnimation) { dropActive = false }
    let videoProviders = info.itemProviders(for: [.movie])
    let imageProviders = info.itemProviders(for: [.image])
    
    guard videoProviders.count <= 1 else { return false }
    guard imageProviders.count <= 4 else { return false }
    
    guard (!videoProviders.isEmpty && imageProviders.isEmpty) ||
            (videoProviders.isEmpty && !imageProviders.isEmpty) else {
              return false
            }
    
    for provider in info.itemProviders(for: [.image]) {
      guard let mediaType = provider.mediaType else { return false }
      
      if twitterClient.selectedMedia.count < 4 {
        let id = UUID().uuidString
        provider.loadItem(forTypeIdentifier: mediaType.identifier, options: nil) { result, error in
          if let error = error {
            print(error)
          } else if let result = result {
            withAnimation {
              DispatchQueue.main.async {
                twitterClient.selectedMedia[id] = NSItemProvider(item: result, typeIdentifier: mediaType.identifier)
              }
            }
          }
        }
      }
    }
    
    for provider in videoProviders {
      guard let mediaType = provider.mediaType else { return false }
      if twitterClient.selectedMedia.count < 1 {
        let id = UUID().uuidString
        provider.loadItem(forTypeIdentifier: mediaType.identifier, options: nil) { result, error in
          if let error = error {
            print(error)
          } else if let result = result {
            withAnimation {
              DispatchQueue.main.async {
                twitterClient.selectedMedia[id] = NSItemProvider(item: result, typeIdentifier: mediaType.identifier)
              }
            }
          }
        }
      }
    }
    
    return true
  }
}
