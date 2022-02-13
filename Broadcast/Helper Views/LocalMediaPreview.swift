//
//  AsyncLocalMediaPreview.swift
//  Broadcast
//
//  Created by Daniel Eden on 29/01/2022.
//

import SwiftUI
import PhotosUI
import AVKit
import QuickLook

struct LocalMediaPreview: View {
  private enum PreviewLoadingState {
    case loadedImage(_ image: UIImage)
    case loadedVideo(_ video: AVPlayer)
    case failed
    case loading
    case loadingWithProgress(_ progress: Progress)
    
    var finished: Bool {
      switch self {
      case .loadedImage(_), .loadedVideo(_), .failed:
        return true
      default:
        return false
      }
    }
  }
  var assetId: String
  var asset: NSItemProvider
  
  @State private var state: PreviewLoadingState = .loading
  @State var loadingProgress: Progress?
  @State private var showLoadingErrorAlert = false
  
  var body: some View {
    Group {
      switch state {
      case .loadedImage(let image):
        Image(uiImage: image)
          .resizable()
          .scaledToFit()
      case .loadedVideo(let player):
        VideoPlayer(player: player)
          .scaledToFit()
      case .failed:
        Label("Cannot Load Preview", systemImage: "eye.slash")
          .foregroundStyle(.secondary)
          .padding()
      case .loading:
        ProgressView("Loading Preview")
          .padding()
      case .loadingWithProgress(let progress):
        ProgressView(value: progress.fractionCompleted)
          .padding()
        
      }
    }
    .frame(maxWidth: .infinity, minHeight: 80)
    .background(.thinMaterial)
    .task { await loadPreview() }
    .onChange(of: loadingProgress) { value in
      if let value = value,
         !value.isFinished {
        withAnimation { self.state = .loadingWithProgress(value) }
      }
    }
  }
  
  func loadPreview() async {
    let itemProvider = asset
    
    guard let typeIdentifier = itemProvider.registeredTypeIdentifiers.last,
          let utType = UTType(typeIdentifier)
    else { return self.state = .failed }
    
    if utType.conforms(to: .image) {
      if itemProvider.canLoadObject(ofClass: UIImage.self) {
        loadingProgress = itemProvider.loadObject(ofClass: UIImage.self) { image, error in
          if let image = image as? UIImage {
            self.state = .loadedImage(image)
          } else {
            self.state = .failed
          }
        }
      }
    } else if utType.conforms(to: .movie) {
      let url: URL? = await withUnsafeContinuation { continuation in
        itemProvider.loadFileRepresentation(forTypeIdentifier: typeIdentifier) { url, error in
          if let error = error {
            print(error.localizedDescription)
          }
          
          guard let url = url else { return continuation.resume(returning: nil) }
          
          let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
          guard let targetURL = documentsDirectory?.appendingPathComponent(url.lastPathComponent) else {
            return continuation.resume(returning: nil)
          }
          
          do {
            if FileManager.default.fileExists(atPath: targetURL.path) {
              try FileManager.default.removeItem(at: targetURL)
            }
            
            try FileManager.default.copyItem(at: url, to: targetURL)
            
            continuation.resume(returning: targetURL)
          } catch {
            continuation.resume(returning: nil)
          }
        }
      }
      
      guard let url = url else {
        return state = .failed
      }
      
      let player = AVPlayer(url: url)
      
      state = .loadedVideo(player)
    } else {
      state = .failed
    }
  }
}
