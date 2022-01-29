//
//  PhotoPicker.swift
//  Broadcast
//
//  Created by Daniel Eden on 26/06/2021.
//

import Foundation
import PhotosUI
import SwiftUI
import Twift

extension PHPickerResult {
  var mediaTypes: [UTType] {
    return self.itemProvider.registeredTypeIdentifiers.compactMap { UTType($0) }
  }
  
  var mediaMimeType: Media.MimeType? {
    return mediaTypes.reduce(nil, { partialResult, current in
      if partialResult == nil,
         let mimeType = current.preferredMIMEType {
        return Media.MimeType(rawValue: mimeType)
      } else {
        return nil
      }
    })
  }
  
  var allowsAltText: Bool {
    guard let mimeType = mediaMimeType else { return false }
    switch mimeType {
    case .gif, .jpeg, .png: return true
    default: return false
    }
  }
}

struct ImagePicker: UIViewControllerRepresentable {
  @Environment(\.presentationMode) var presentationMode
  var configuration: PHPickerConfiguration = PHPickerConfiguration(photoLibrary: PHPhotoLibrary.shared())
  
  @Binding var selection: [String: PHPickerResult]
  
  func makeUIViewController(context: UIViewControllerRepresentableContext<ImagePicker>) -> PHPickerViewController {
    let controller = PHPickerViewController(configuration: configuration)
    controller.delegate = context.coordinator
    
    return controller
  }
  
  func updateUIViewController(_ uiViewController: PHPickerViewController, context: UIViewControllerRepresentableContext<ImagePicker>) {
    
  }
  
  func makeCoordinator() -> Coordinator {
    Coordinator(self)
  }
  
  class Coordinator: PHPickerViewControllerDelegate {
    let parent: ImagePicker
    
    init(_ parent: ImagePicker) {
      self.parent = parent
    }
    
    func picker(_: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
      for result in results {
        self.parent.selection[result.assetIdentifier!] = result
      }
      
      self.parent.presentationMode.wrappedValue.dismiss()
    }
  }
}
