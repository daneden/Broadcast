//
//  RemoteImage.swift
//  Broadcast
//
//  Created by Daniel Eden on 28/06/2021.
//

import SwiftUI
import Combine
import UIKit

class ImageLoader: ObservableObject {
  @Published var image: UIImage?
  private let url: URL
  
  init(url: URL) {
    self.url = url
  }
  
  deinit {
    cancel()
  }
  
  private var cancellable: AnyCancellable?
  
  func load() {
    cancellable = URLSession.shared.dataTaskPublisher(for: url)
      .map { UIImage(data: $0.data) }
      .replaceError(with: nil)
      .receive(on: DispatchQueue.main)
      .sink { [weak self] image in
        withAnimation { self?.image = image }
      }
  }
  
  func cancel() {
    cancellable?.cancel()
  }
}

struct RemoteImage<Placeholder: View>: View {
  @StateObject private var loader: ImageLoader
  private let placeholder: Placeholder
  
  init(url: URL, @ViewBuilder placeholder: () -> Placeholder) {
    self.placeholder = placeholder()
    _loader = StateObject(wrappedValue: ImageLoader(url: url))
  }
  
  var body: some View {
    content
      .onAppear(perform: loader.load)
  }
  
  private var content: some View {
    Group {
      if loader.image != nil {
        Image(uiImage: loader.image!)
          .resizable()
      } else {
        placeholder
      }
    }
  }
}
