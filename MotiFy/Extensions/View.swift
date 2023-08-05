//
//  View.swift
//  MotiFy
//
//  Created by Daniel on 8/4/23.
//

import SwiftUI

struct AlertData {
    let title: String
    let message: String
    let additionalButton: Button<Text>?
    
    init(title: String, message: String, additionalButton: Button<Text>? = nil) {
        self.title = title
        self.message = message
        self.additionalButton = additionalButton
    }
}

extension View {
    
    /// Shows alert when alert data value is present
    func alert(_ alert: Binding<AlertData?>) -> some View {
        Group {
            if let model = alert.wrappedValue {
                return self.alert(model.title, isPresented: .constant(true)) {
                    Button("OK") {
                        alert.wrappedValue = nil
                    }
                    
                    model.additionalButton

                } message: {
                    Text(model.message)
                }
            } else {
                return self.alert("", isPresented: .constant(false)) {
                    Button("OK") {
                    }
                    alert.wrappedValue?.additionalButton
                } message: {
                    Text("")
                }
            }
        }
    }
}
