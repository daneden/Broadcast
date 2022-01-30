//
//  AsyncLocalMediaPreview.swift
//  Broadcast
//
//  Created by Daniel Eden on 29/01/2022.
//

import SwiftUI
import PhotosUI
import QuickLook

struct AsyncLocalMediaPreview: View {
  private enum PreviewLoadingState {
    case loaded(_ image: UIImage)
    case failed
    case loading
    case loadingWithProgress(_ progress: Progress)
    
    var finished: Bool {
      switch self {
      case .loaded(_), .failed:
        return true
      default:
        return false
      }
    }
  }
  var assetId: String
  var asset: PHPickerResult
  
  @State private var state: PreviewLoadingState = .loading
  @State var loadingProgress: Progress?
  
  var body: some View {
    Group {
      switch state {
      case .loaded(let image):
        Image(uiImage: image)
          .resizable()
          .scaledToFit()
      case .failed:
        Label("Cannot load media", systemImage: "eye.slash")
          .foregroundStyle(.secondary)
          .padding()
      case .loading:
        ProgressView()
          .padding()
      case .loadingWithProgress(let progress):
        ProgressView(value: progress.fractionCompleted)
          .padding()
      }
    }
    .frame(maxWidth: .infinity, minHeight: 48)
    .background(.thinMaterial)
    .task { await loadPreview() }
    .onChange(of: loadingProgress) { value in
      if let value = value,
         !value.isFinished {
        self.state = .loadingWithProgress(value)
      }
    }
  }
  
  func loadPreview() async {
    let itemProvider = asset.itemProvider
    
    guard let typeIdentifier = itemProvider.registeredTypeIdentifiers.first,
          let utType = UTType(typeIdentifier)
    else { return self.state = .failed }
    
    if utType.conforms(to: .image),
       itemProvider.canLoadObject(ofClass: UIImage.self) {
      loadingProgress = itemProvider.loadObject(ofClass: UIImage.self) { image, error in
        if let image = image as? UIImage {
          self.state = .loaded(image)
        } else {
          self.state = .failed
        }
      }
    } else if utType.conforms(to: .video) {
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

      let thumbnailRequest = QLThumbnailGenerator.Request.init(fileAt: url, size: .init(width: 800, height: 800), scale: 3.0, representationTypes: .thumbnail)
      guard let thumbnail = try? await QLThumbnailGenerator().generateBestRepresentation(for: thumbnailRequest) else {
        return state = .failed
      }
      
      state = .loaded(thumbnail.uiImage)
    } else {
      state = .failed
    }
  }
}
