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
  var mediaType: UTType? {
    guard let registeredTypeIdentifier = self.itemProvider.registeredTypeIdentifiers.first else {
      return nil
    }
    return UTType(registeredTypeIdentifier)
  }
  
  var mediaMimeType: Media.MimeType? {
    guard let utTypeMimeType = mediaType?.preferredMIMEType else { return nil }
    return .init(rawValue: utTypeMimeType)
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
