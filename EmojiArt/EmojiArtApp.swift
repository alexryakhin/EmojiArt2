//
//  EmojiArtApp.swift
//  EmojiArt
//
//  Created by Alexander Bonney on 9/8/21.
//

import SwiftUI

@main
struct EmojiArtApp: App {
    
    let document = EmojiArtDocument()
    
    var body: some Scene {
        WindowGroup {
            EmojiArtDocumentView(document: document)
        }
    }
}
