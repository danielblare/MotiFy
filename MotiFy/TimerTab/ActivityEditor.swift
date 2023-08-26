//
//  ActivityEditor.swift
//  MotiFy
//
//  Created by Daniel on 8/16/23.
//

import SwiftUI

/// A view for editing an activity's details.
struct ActivityEditor: View {
    /// A binding to the activity being edited.
    @Binding var activity: Activity
    
    /// Indicates whether the display text is the same as the activity's name.
    @State private var sameDisplayText: Bool
    
    /// Represents the focused field in the view.
    @FocusState private var focused: FocusedField?
    
    /// Represents the fields that can be focused in the view.
    enum FocusedField {
        case name, displayText
    }
    
    /// Initializes the view with a binding to an activity.
    init(for activity: Binding<Activity>) {
        self._activity = activity
        self.sameDisplayText = activity.wrappedValue.name == activity.wrappedValue.displayText
    }
    
    var body: some View {
        List {
            // Section for entering name and display text
            Section {
                TextField("Enter name", text: $activity.name) { focused = .displayText }
                    .focused($focused, equals: .name)
                
                TextField("Enter display text", text: $activity.displayText)
                    .focused($focused, equals: .displayText)
            } header: {
                Text("Visual") // Header for the section
            } footer: {
                Text("Text displayed when timer is running") // Footer for the section
            }
            
            // Section for setting default time
            Section {
                HStack {
                    Text("Default time")
                    
                    Spacer(minLength: 0)
                    
                    TimeSelector(time: $activity.defaultTime)
                        .frame(height: 100)
                }
            } footer: {
                Text("Default time set for this activity") // Footer for the section
            }
        }
        .scrollDismissesKeyboard(.interactively) // Dismiss the keyboard when scrolling
        .onChange(of: activity.name) { newValue in
            let symbolLimit = Activity.nameSymbolLimit
            if newValue.count > symbolLimit {
                activity.name = String(newValue.prefix(symbolLimit)) // Truncate name if too long
            }
        }
        
        .onChange(of: activity.displayText) { newValue in
            let symbolLimit = Activity.displayTextSymbolLimit
            if newValue.count > symbolLimit {
                activity.displayText = String(newValue.prefix(symbolLimit)) // Truncate display text if too long
            }
        }
        
        .onChange(of: activity.name) { newValue in
            if sameDisplayText {
                activity.displayText = newValue // Update display text if sameDisplayText is true
            }
        }
        .onChange(of: activity.displayText) { newValue in
            if focused == .displayText, sameDisplayText {
                sameDisplayText = false // Disable sameDisplayText if display text field changes
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
