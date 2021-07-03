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
  @EnvironmentObject var twitterClient: TwitterClient
  @EnvironmentObject var themeHelper: ThemeHelper
  
  var body: some View {
    NavigationView {
      List {
        if twitterClient.drafts.isEmpty {
          Text("No Saved Drafts").foregroundColor(.secondary)
        }
        
        ForEach(Array(twitterClient.drafts), id: \.self) { draft in
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
            
            if let mediaData = draft.media {
              Image(uiImage: UIImage(data: mediaData)!)
                .resizable()
                .aspectRatio(contentMode: .fit)
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
      .toolbar {
        Button(action: { presentationMode.wrappedValue.dismiss() }) {
          Text("Close")
        }
      }
      .font(.broadcastBody)
      .navigationTitle("Drafts")
    }.accentColor(themeHelper.color)
  }
  
  func deleteDrafts(at offsets: IndexSet) {
    var collection = Array(twitterClient.drafts)
    collection.remove(atOffsets: offsets)
    twitterClient.drafts = Set(collection)
  }
}

struct DraftsListView_Previews: PreviewProvider {
    static var previews: some View {
        DraftsListView()
    }
}