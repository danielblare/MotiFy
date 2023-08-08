//
//  Color.swift
//  MotiFy
//
//  Created by Daniel on 8/6/23.
//

import SwiftUI

extension Color {
    static let palette: Palette = Palette()
    
    struct Palette {
        let color1 = Color("color1")
        let color2 = Color("color2")
        let color3 = Color("color3")
        let color4 = Color("color4")
        let color5 = Color("color5")
        let color6 = Color("color6")
        
        var colorSet: Set<Color> {
            [color1, color2, color3, color4, color5, color6]
        }
    }
}

extension Color {
    
    /// Returns white or black depending on which one is more contrasting to self
    func contrastingTextColor() -> Color {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        UIColor(self).getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        let brightness = ((red * 299) + (green * 587) + (blue * 114)) / 1000
        return brightness < 0.5 ? .white : .black
    }
    
    func colorComponents() throws -> (red: Double, green: Double, blue: Double, alpha: Double) {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        
        guard UIColor(self).getRed(&r, green: &g, blue: &b, alpha: &a) else { throw ColorError.cannotConvert }
        
        return (r, g, b, a)
    }
    
    enum ColorError: Error {
        /// Indicates that Color cannot be convertible to the RGB space
        case cannotConvert
    }
}
