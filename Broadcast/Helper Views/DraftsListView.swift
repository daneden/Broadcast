//
//  DraftsListView.swift
//  Broadcast
//
//  Created by Daniel Eden on 03/07/2021.
//

import SwiftUI

struct DraftsListView: View {
  @ScaledMetric var thumbnailSize: CGFloat = 56
  @Environment(\.presentationMode) var presentationMode
  @Environment(\.managedObjectContext) var managedObjectContext
  
  @FetchRequest(entity: Draft.entity(), sortDescriptors: [NSSortDescriptor(keyPath: \Draft.date, ascending: true)])
  var drafts: FetchedResults<Draft>
  
  @EnvironmentObject var twitterClient: TwitterClientManager
  @EnvironmentObject var themeHelper: ThemeHelper
  
  var body: some View {
    NavigationView {
      Group {
        if drafts.isEmpty {
          NullStateView(type: .drafts)
        } else {
          List {
            ForEach(drafts) { draft in
              HStack {
                VStack(alignment: .leading) {
                  if let date = draft.date {
                    Text(date, style: .date)
                      .font(.broadcastFootnote)
                      .foregroundColor(.secondary)
                  }
                  
                  if let text = draft.text {
                    Text(text)
                  } else {
                    Text("Empty Draft").foregroundColor(.secondary)
                  }
                }
                
                Spacer()
                
                if let imageData = draft.media,
                   let image = UIImage(data: imageData) {
                  Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: thumbnailSize, height: thumbnailSize)
                    .cornerRadius(8)
                }
              }
              .contentShape(Rectangle())
              .onTapGesture {
                presentationMode.wrappedValue.dismiss()
                twitterClient.retreiveDraft(draft: draft)
              }
            }.onDelete(perform: deleteDrafts)
          }
        }
      }
      .toolbar {
        EditButton()
        
        Button(action: { presentationMode.wrappedValue.dismiss() }) {
          Text("Close")
        }
      }
      .font(.broadcastBody)
      .navigationTitle("Drafts")
    }.accentColor(themeHelper.color)
  }
  
  func deleteDrafts(at offsets: IndexSet) {
    for index in offsets {
      let draft = drafts[index]
      managedObjectContext.delete(draft)
    }
    
    PersistanceController.shared.save()
  }
}

struct DraftsListView_Previews: PreviewProvider {
  static var previews: some View {
    DraftsListView()
  }
}
