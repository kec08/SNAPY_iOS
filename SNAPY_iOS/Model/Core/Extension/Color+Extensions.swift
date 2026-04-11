//
//  Color+Extensions.swift
//  voiceMemo
//

import SwiftUI

extension Color {
    static let MainYellow = Color("MainYellow")
    static let customWhite = Color("TextWhite")
    
    static let BackgroundBlack = Color("BackgroundBlack")
    static let Gray100 = Color("Gray100")
    static let Gray200 = Color("Gray200")
    static let Gray300 = Color("Gray300")
    static let Gray400 = Color("Gray400")
    static let Gray500 = Color("Gray500")
    static let DarkGray = Color("DarkGray")
    
    static let customRed = Color("ActionRed")
    static let customBlue = Color("ActionBlue")
    static let customGreen = Color("ActionGreen")
    static let customOrange = Color("SubOrange")
    static let customWhiteYellow = Color("SubWhiteYellow")
    
    init(hex: String) {
        let scanner = Scanner(string: hex)
        _ = scanner.scanString("#")
        
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        
        let r = Double((rgb >> 16) & 0xFF) / 255
        let g = Double((rgb >> 8) & 0xFF) / 255
        let b = Double(rgb & 0xFF) / 255
        
        self.init(red: r, green: g, blue: b)
    }
}

