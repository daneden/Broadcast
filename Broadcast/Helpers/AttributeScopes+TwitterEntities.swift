//
//  AttributeScopes+TwitterEntities.swift
//  Broadcast
//
//  Created by Daniel Eden on 28/01/2022.
//

import Foundation

struct Entity: Hashable, Codable {
  let value: String
}

struct EntityAttribute: CodableAttributedStringKey, MarkdownDecodableAttributedStringKey {
  typealias Value = Entity
  
  static var name: String = "entity"
  
}

extension AttributeScopes {
  struct BroadcastAttributes: AttributeScope {
    let entity: EntityAttribute
    let swiftUI: SwiftUIAttributes
  }
  
  var broadcast: BroadcastAttributes.Type { BroadcastAttributes.self }
}

extension AttributeDynamicLookup {
  subscript<T: AttributedStringKey>(dynamicMember keyPath: KeyPath<AttributeScopes.BroadcastAttributes, T>) -> T {
    self[T.self]
  }
}
