//
//  NoShape.swift
//  Broadcast
//
//  Created by Daniel Eden on 27/06/2021.
//

import SwiftUI

struct NoShape: Shape {
  func path(in rect: CGRect) -> Path {
    return Path()
  }
}

struct NoShape_Previews: PreviewProvider {
    static var previews: some View {
        NoShape()
    }
}
