//
//  ComposerView.swift
//  Broadcast
//
//  Created by Daniel Eden on 30/06/2021.
//

import SwiftUI
import TwitterText
import Twift

fileprivate let placeholderCandidates: [String] = [
  "Wh—what’s going on?",
  "Oh hey uh, what’s up",
  "What’s Twitter?",
  "Tweet away, sweet child",
  "Say something nice",
  "Cowabunga, dude",
  "You’re doing a great job"
]

struct ComposerView: View {
  let debouncer = Debouncer(timeInterval: 0.3)
  
  @EnvironmentObject var twitterClient: TwitterClientManager
  @ScaledMetric private var minComposerHeight: CGFloat = 120
  @ScaledMetric private var captionSize: CGFloat = 14
  @ScaledMetric private var leftOffset: CGFloat = 4
  @ScaledMetric private var verticalPadding: CGFloat = 6
  
  @State private var placeholder: String = placeholderCandidates.randomElement()
  @State private var draftListVisible = false
  
  private let mentioningRegex = NSRegularExpression("@[a-z0-9_]+$", options: .caseInsensitive)
  
  private var tweetText: String {
    twitterClient.draft.text ?? ""
  }
  
  private var mentionString: String? {
    mentioningRegex.firstMatchAsString(tweetText)
  }
  
  private var charCount: Int {
    TwitterText.tweetLength(text: tweetText)
  }
  
  private var mentionCandidates: [User]? {
    twitterClient.userSearchResults
  }
  
  private var tweetLengthWarning: String {
    switch charCount {
    case 380...479:
      return " (ok c’mon dude)"
    case 480...679:
      return " (this isn’t the notes app)"
    case 680...1023:
      return " (the app probably looks pretty bad right now, huh)"
    case 1024...2047:
      return " (I bet you’re wondering when this will stop)"
    case 2048...19999:
      return " (you’re really gonna keep going?)"
    case 20000...30000:
      return " (I’m impressed, really)"
    case 30000...42348:
      return " (almost there)"
    case 42349:
      return " (nice)"
    case 42350...Int.max:
      return " (fin)"
    default:
      return ""
    }
  }
  
  var body: some View {
    ZStack(alignment: .bottom) {
      VStack(alignment: .trailing) {
        HStack(alignment: .top) {
          Menu {
            Section {
              Button(role: .destructive, action: {twitterClient.signOut()}) {
                Label("Sign Out", systemImage: "person.badge.minus")
              }
            }
          } label: {
            AsyncImage(url: twitterClient.user?.profileImageUrlLarger) { image in
              image
                .resizable()
                .aspectRatio(contentMode: .fill)
                .cornerRadius(36)
            } placeholder: {
              ProgressView()
            }
            .background(.regularMaterial)
            .frame(width: 36, height: 36)
          }
          
          ZStack(alignment: .topLeading) {
            Text(tweetText.isEmpty ? placeholder : tweetText)
              .padding(.leading, leftOffset)
              .padding(.vertical, verticalPadding)
              .foregroundColor(Color(.placeholderText))
              .opacity(tweetText.isEmpty ? 1 : 0)
              .accessibility(hidden: true)
            
            TextEditor(text: Binding($twitterClient.draft.text, replacingNilWith: ""))
              .foregroundColor(Color(.label))
              .multilineTextAlignment(.leading)
              .keyboardType(.twitter)
              .padding(.top, (verticalPadding / 3) * -1)
              .accessibilityIdentifier("tweetComposer")
          }
          .font(.broadcastTitle3)
        }.transition(.scale)
        
        Divider()
        
        HStack(alignment: .top) {
          Menu {
            Button(action: { twitterClient.saveDraft() }) {
              Label("Save Draft", systemImage: "square.and.pencil")
            }.disabled(!twitterClient.draftIsValid())
            
            Button(action: { draftListVisible = true }) {
              Label("View Drafts", systemImage: "doc.on.doc")
            }
          } label: {
            Label("Drafts", systemImage: "doc.on.doc")
              .font(.broadcastFootnote)
          }
          
          Spacer()
          
          Text("\(280 - charCount)\(tweetLengthWarning)")
            .foregroundColor(charCount > 200 ? charCount >= 280 ? Color(.systemRed) : Color(.systemOrange) : .secondary)
            .font(.system(size: min(captionSize * max(CGFloat(charCount) / 280, 1), 28), weight: .bold, design: .rounded))
            .multilineTextAlignment(.trailing)
        }
      }
      .disabled(twitterClient.state == .busy())
      .padding()
      .background(Color(.tertiarySystemGroupedBackground))
      .onShake {
        rotatePlaceholder()
        Haptics.shared.sendStandardFeedback(feedbackType: .success)
      }
      .onChange(of: twitterClient.draftIsValid()) { isValid in
        if !isValid && charCount > 280 {
          Haptics.shared.sendStandardFeedback(feedbackType: .warning)
        }
      }
      .sheet(isPresented: $draftListVisible) {
        DraftsListView()
          .environmentObject(ThemeHelper.shared)
          .environment(\.managedObjectContext, PersistanceController.shared.context)
      }
      .onChange(of: mentionString) { value in
        if let screenName = value {
          debouncer.renewInterval()
          debouncer.handler = {
            Task {
              await self.twitterClient.searchScreenNames(screenName)
            }
          }
        }
      }
      
      if let users = mentionCandidates,
         !users.isEmpty,
         let mentionString = mentionString,
         !mentionString.isEmpty {
        MentionBar(users: users) { user in
          completeMention(user)
        }
      }
    }.cornerRadius(captionSize)
  }
  
  func completeMention(_ user: User) {
    let textToComplete = mentioningRegex.firstMatchAsString(tweetText) ?? ""
    let draft = twitterClient.draft.text?.replacingOccurrences(of: textToComplete, with: "@\(user.username) ")
    twitterClient.draft.text = draft
  }
  
  func rotatePlaceholder() {
    var newPlaceholder = placeholder
    
    while newPlaceholder == placeholder {
      newPlaceholder = placeholderCandidates.randomElement()
    }
    
    placeholder = newPlaceholder
  }
}

struct ComposerView_Previews: PreviewProvider {
    static var previews: some View {
      ComposerView()
    }
}
