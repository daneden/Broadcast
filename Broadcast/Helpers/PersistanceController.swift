//
//  PersistanceController.swift
//  Broadcast
//
//  Created by Daniel Eden on 10/07/2021.
//

import Foundation
import CoreData

struct PersistanceController {
  static let shared = PersistanceController()
  
  let container: NSPersistentContainer
  var context: NSManagedObjectContext {
    container.viewContext
  }
  
  static var preview: PersistanceController {
    let controller = PersistanceController(inMemory: true)
    
    for i in 0..<10 {
      let draft = Draft(context: controller.container.viewContext)
      draft.text = "Test draft \(i)"
      draft.date = Date()
      draft.id = UUID()
    }
    
    return controller
  }
  
  init(inMemory: Bool = false) {
    container = NSPersistentContainer(name: "DraftsModel")
    
    if inMemory {
      container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
    }
    
    container.loadPersistentStores { description, error in
      if let error = error {
        fatalError("Error: \(error.localizedDescription)")
      }
    }
  }
  
  func save() {
    let context = container.viewContext
    
    if context.hasChanges {
      do {
        try context.save()
      } catch {
        print(error.localizedDescription)
      }
    }
  }
}
