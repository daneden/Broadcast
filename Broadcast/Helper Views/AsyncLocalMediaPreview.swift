//
//  AsyncLocalMediaPreview.swift
//  Broadcast
//
//  Created by Daniel Eden on 29/01/2022.
//

import SwiftUI
import PhotosUI

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
        ProgressView(progress)
          .padding()
      }
    }
    .transition(.opacity)
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
    if itemProvider.canLoadObject(ofClass: UIImage.self) {
      loadingProgress = itemProvider.loadObject(ofClass: UIImage.self) { image, error in
        if let image = image as? UIImage {
          self.state = .loaded(image)
        } else {
          self.state = .failed
        }
      }
    } else {
      self.state = .failed
    }
  }
}
