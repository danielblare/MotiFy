//
//  ActivityEditor.swift
//  MotiFy
//
//  Created by Daniel on 8/16/23.
//

import SwiftUI

struct ActivityEditor: View {
    @Binding var activity: Activity
    
    @State private var sameDisplayText: Bool
    
    @FocusState private var focused: FocusedField?
    
    enum FocusedField {
        case name, displayText
    }
    init(for activity: Binding<Activity>) {
        self._activity = activity
        self.sameDisplayText = activity.wrappedValue.name == activity.wrappedValue.displayText
    }
    
    var body: some View {
        List {
            Section {
                TextField("Enter name", text: $activity.name) { focused = .displayText }
                    .focused($focused, equals: .name)
                
                TextField("Enter display text", text: $activity.displayText)
                    .focused($focused, equals: .displayText)

            } header: {
                Text("Visual")
            } footer: {
                Text("Text displayed when timer is running")
            }
            
            Section {
                HStack {
                    Text("Default time")
                    
                    Spacer(minLength: 0)
                    
                    TimeSelector(time: $activity.defaultTime)
                }
            } footer: {
                Text("Defaut time set for this activity")
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .onChange(of: activity.name) { newValue in
            let symbolLimit = Activity.nameSymbolLimit
            if newValue.count > symbolLimit {
                activity.name = String(newValue.prefix(symbolLimit))
            }
        }
        
        .onChange(of: activity.displayText) { newValue in
            let symbolLimit = Activity.displayTextSymbolLimit
            if newValue.count > symbolLimit {
                activity.displayText = String(newValue.prefix(symbolLimit))
            }
        }

        .onChange(of: activity.name) { newValue in
            if sameDisplayText {
                activity.displayText = newValue
            }
        }
        .onChange(of: activity.displayText) { newValue in
            if focused == .displayText, sameDisplayText {
                sameDisplayText = false
            }
        }
    }
}

#Preview {
    @State var cat: Activity = Activity(name: "work", displayText: "doiajwd adainwdiad af a wfa wf a wf aw fawf w fa f")
    return NavigationStack {
        ActivityEditor(for: $cat)
    }
}
