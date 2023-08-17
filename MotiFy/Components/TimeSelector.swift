//
//  TimeSelector.swift
//  MotiFy
//
//  Created by Daniel on 8/17/23.
//

import SwiftUI

struct TimeSelector: View {
    
    @Binding private var time: Time
    
    @FocusState private var focused: FocusedField?
    
    enum FocusedField {
        case hours, minutes, seconds
    }
    
    init(time: Binding<Time>) {
        self._time = time
    }
        
    var body: some View {
        HStack(spacing: 0) {
            TextField("", value: $time.hours, formatter: NumberFormatter.hoursFormatter)
                .focused($focused, equals: .hours)
                .padding(3)
                .frame(width: 30)
                .background(focused == .hours ? .blue : .clear)
                .clipShape(RoundedRectangle(cornerRadius: 5))
                .tint(.clear)

            Text(":")
            
            TextField("", value: $time.minutes, formatter: NumberFormatter.minutesAndSecondsFormatter)
                .focused($focused, equals: .minutes)
                .padding(3)
                .frame(width: 30)
                .background(focused == .minutes ? .blue : .clear)
                .clipShape(RoundedRectangle(cornerRadius: 5))
                .tint(.clear)

            Text(":")
            
            TextField("", value: $time.seconds, formatter: NumberFormatter.minutesAndSecondsFormatter)
                .focused($focused, equals: .seconds)
                .padding(3)
                .frame(width: 30)
                .background(focused == .seconds ? .blue : .clear)
                .clipShape(RoundedRectangle(cornerRadius: 5))
                .tint(.clear)

        }
        .multilineTextAlignment(.center)
        .monospacedDigit()
        .keyboardType(.numberPad)

        .onReceive(NotificationCenter.default.publisher(for: UITextField.textDidBeginEditingNotification)) { obj in
            if let textField = obj.object as? UITextField {
                textField.selectedTextRange = textField.textRange(from: textField.beginningOfDocument, to: textField.endOfDocument)
            }
        }
    }
}

extension NumberFormatter {
    static var hoursFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.minimum = 0
        formatter.maximum = 23
        return formatter
    }
    
    static var minutesAndSecondsFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.minimum = 0
        formatter.maximum = 59
        return formatter
    }

}

#Preview {
    TimeSelector(time: .constant(Time.init()))
}
