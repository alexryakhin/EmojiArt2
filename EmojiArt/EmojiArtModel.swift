//
//  EmojiArtModel.swift
//  EmojiArtModel
//
//  Created by Alexander Bonney on 9/8/21.
//

import Foundation

struct EmojiArtModel {
    
    var background = Background.blank
    var emojis = [Emoji]()
    
    struct Emoji: Identifiable, Hashable {
        let text: String
        var x: Int // offset from the center
        var y: Int // offset from the center
        var size: Int
        let id: Int
        
        //anyone in this file can use this init, so nobody can create an emoji exept us
        fileprivate init(text: String, x: Int, y: Int, size: Int, id: Int) {
            self.text = text
            self.x = x
            self.y = y
            self.size = size
            self.id = id
        }
    }
    
    init() { }
    
    private var uniqueEmojiId = 0
   
    mutating func addEmoji(_ text: String, at location: (x: Int, y: Int), size: Int) {
        uniqueEmojiId += 1
        emojis.append(Emoji(text: text, x: location.x, y: location.y, size: size, id: uniqueEmojiId))
        
    }
    
    mutating func removeEmoji(_ selectedEmojis: Set<Emoji>) {
        for emoji in emojis {
            for selectedEmoji in selectedEmojis {
                if emoji == selectedEmoji {
                    emojis.remove(emoji)
                }
            }
        }
    }
    
    
    
}
