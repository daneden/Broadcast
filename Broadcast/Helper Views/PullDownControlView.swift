//
//  PullDownControlView.swift
//  Broadcast
//
//  Created by Daniel Eden on 02/07/2021.
//

import SwiftUI

struct PullDownControlView<Content: View>: View {
  var threshold: CGFloat
  var coordinateSpace: CoordinateSpace
  var onPullDown: () -> Void
  var content: Content
  
  init(threshold: CGFloat = 50, coordinateSpace: CoordinateSpace, onPullDown: @escaping () -> Void, @ViewBuilder content: @escaping () -> Content) {
    self.threshold = threshold
    self.coordinateSpace = coordinateSpace
    self.onPullDown = onPullDown
    self.content = content()
  }
  
  @State var triggered: Bool = false
  var body: some View {
    GeometryReader { geo in
      if (geo.frame(in: coordinateSpace).midY > threshold) {
        Spacer()
          .onAppear {
            if triggered == false {
              onPullDown()
            }
            
            Haptics.shared.sendFeedback(intensity: 1.0, sharpness: 0.8)
            triggered = true
          }
      } else if (geo.frame(in: coordinateSpace).maxY < threshold) {
        Spacer()
          .onAppear {
            triggered = false
          }
      }
      GeometryReader { context in
        content
          .padding(.top, context.size.height * -1)
          .opacity(Double(geo.frame(in: coordinateSpace).minY / context.size.height))
          .disabled(!triggered)
      }
    }
  }
}
