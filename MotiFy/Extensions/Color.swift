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
