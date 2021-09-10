//
//  EmojiArtModel.Background.swift
//  EmojiArtModel.Background
//
//  Created by Alexander Bonney on 9/8/21.
//

import Foundation

extension EmojiArtModel {
    
    //assossiated data
    enum Background: Equatable {
        case blank
        case url(URL)
        case imageData(Data)
        
        var url: URL? {
            switch self {
            case .url(let url): return url
            default: return nil
            }
        }
        
        var data: Data? {
            switch self {
            case .imageData(let data):
                return data
            default: return nil
            }
        }
    }
    
    
    
    
}
