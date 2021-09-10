//
//  ContentView.swift
//  EmojiArt
//
//  Created by Alexander Bonney on 9/8/21.
//

import SwiftUI

struct EmojiArtDocumentView: View {
    //view model
    @ObservedObject var document: EmojiArtDocument
    @State private var selectedEmojis = Set<EmojiArtModel.Emoji>()
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                documentBody
                buttons
            }
            palette
        }
    }
    
    var documentBody: some View {
        GeometryReader { geometry in
            ZStack {
                Color.white.overlay(
                    OptionalImage(uiImage: document.backgroundImage)
                        .scaleEffect(zoomScale)
                        .position(convertFromEmojiCoordinates((x: 0, y: 0), in: geometry))
                )
                    .gesture(doubleTapToZoom(in: geometry.size))
                if document.backgroundImageFetchingStatus == .fetching {
                    ProgressView()
                }
                ForEach(document.emojis) { emoji in
                    Text(emoji.text)
                        .padding(6)
                        .overlay(
                            Circle().stroke(lineWidth: selectedEmojis.contains(emoji) ? 1 : 0)
                        )
                        .font(.system(size: fontSize(for: emoji)))
                        .scaleEffect(zoomScale)
                        .position(position(for: emoji, in: geometry))
                        .shadow(color: .purple.opacity(selectedEmojis.contains(emoji) ? 1 : 0), radius: 5, x: 0, y: 0)
                        .gesture(tapToSelect(emoji))
                }
            }
            .clipped()
            .onDrop(of: [.plainText, .url, .image], isTargeted: nil) { providers, location in
                return drop(providers: providers, at: location, in: geometry)
            }
            .gesture(panGesture().simultaneously(with: zoomGesture().exclusively(before: tapToDeselect()))) //never put two gestures on the same view
        }
    }
    
    private func fontSize(for emoji: EmojiArtModel.Emoji) -> CGFloat {
        CGFloat(emoji.size)
    }
    
    private func position(for emoji: EmojiArtModel.Emoji, in geometry: GeometryProxy) -> CGPoint {
        convertFromEmojiCoordinates((emoji.x, emoji.y), in: geometry)
    }
    
    private func convertToEmojiCoordinates(_ location: CGPoint, in geometry: GeometryProxy) -> (x: Int, y: Int) {
        let center = geometry.frame(in: .local).center
        let location = CGPoint(
            x: (location.x - panOffset.width - center.x) / zoomScale,
            y: (location.y - panOffset.height - center.y) / zoomScale
        )
        return (Int(location.x), Int(location.y))
    }
    
    private func convertFromEmojiCoordinates(_ location: (x: Int, y: Int), in geometry: GeometryProxy) -> CGPoint {
        let center = geometry.frame(in: .local).center

        return CGPoint(
            x: center.x + CGFloat(location.x) * zoomScale + panOffset.width,
            y: center.y + CGFloat(location.y) * zoomScale + panOffset.height
        )
    }
    
    //handling drop
    private func drop(providers: [NSItemProvider], at location: CGPoint, in geometry: GeometryProxy) -> Bool {
        var found = providers.loadObjects(ofType: URL.self) { url in
            document.setBackground(.url(url.imageURL))
        }
        
        if !found {
            found = providers.loadObjects(ofType: UIImage.self) { image in
                if let imageData = image.jpegData(compressionQuality: 1.0) {
                    document.setBackground(.imageData(imageData))
                }
            }
        }
        
        if !found {
            found = providers.loadObjects(ofType: String.self) { string in
                if let emoji = string.first, emoji.isEmoji {
                    document.addEmoji(String(emoji),
                                      at: convertToEmojiCoordinates(location, in: geometry),
                                      size: defaultFontSize / zoomScale)
                }
            }
        }
        return found
    }
    
    //panning gesture
    @State private var steadyStatePanOffset: CGSize = .zero
    @GestureState private var gesturePanOffset: CGSize = .zero

    private var panOffset: CGSize {
        (steadyStatePanOffset + gesturePanOffset) * zoomScale
    }
    
    private func panGesture() -> some Gesture {
        DragGesture()
            .updating($gesturePanOffset) { latestDragGestureValue, gesturePanOffset, _ in
                gesturePanOffset = latestDragGestureValue.translation / zoomScale
            }
            .onEnded { finalDragGestureValue in
                steadyStatePanOffset = steadyStatePanOffset + (finalDragGestureValue.translation / zoomScale)
            }
    }
    
    //zoom gesture
    @State private var steadyStateZoomScale: CGFloat = 1
    @GestureState private var gestureZoomScale: CGFloat = 1
    
    private var zoomScale: CGFloat {
        steadyStateZoomScale * gestureZoomScale
    }
    
    private func zoomToFit(_ image: UIImage?, in size: CGSize) {
        if let image = image, image.size.width > 0, image.size.height > 0, size.width > 0, size.height > 0 {
            let hZoom = size.width / image.size.width
            let vZoom = size.height / image.size.height
            steadyStatePanOffset = .zero
            steadyStateZoomScale = min(hZoom, vZoom)
        }
    }
    
    private func zoomGesture() -> some Gesture {
        MagnificationGesture()
            .updating($gestureZoomScale) { latestGestureScale, gestureZoomScale, _ in
                gestureZoomScale = latestGestureScale
            }
            .onEnded { gestureScaleAtEnd in
                steadyStateZoomScale *= gestureScaleAtEnd
            }
    }
    
    //tapping gestures
    private func doubleTapToZoom(in size: CGSize) -> some Gesture {
        TapGesture(count: 2)
            .onEnded {
                withAnimation {
                    zoomToFit(document.backgroundImage, in: size)
                }
            }
    }
    
    private func tapToDeselect() -> some Gesture {
        TapGesture(count: 1)
            .onEnded { _ in
                selectedEmojis.removeAll()
            }
    }
    
    private func tapToSelect(_ emoji: EmojiArtModel.Emoji) -> some Gesture {
        TapGesture(count: 1)
            .onEnded { _ in
                if !selectedEmojis.contains(emoji) {
                    selectedEmojis.insert(emoji)
                } else {
                    selectedEmojis.remove(emoji)
                }
            }
    }
    
    var palette: some View {
        ScrollingEmojisView(emojis: emojisTest)
            .font(.system(size: defaultFontSize))
    }
    
    var buttons: some View {
        VStack {
            HStack {
                Spacer()
                if !selectedEmojis.isEmpty {
                    Button {
                        document.removeEmoji(selectedEmojis)
                        selectedEmojis.removeAll()
                    } label: {
                        Text("delete").padding()
                    }
                }
            }
            Spacer()
        }
    }
    
    let emojisTest = "🧞🧞‍♂️🧜‍♀️🧜👁💪🏻👍🏻👽🎃💩👻💀🦾🦂🦀🐠🦖🦋🐌🐊🦒🕊🦢🦜🐕🐁🐚🌈☄️✨⚽️🎼🎺🎻🎸✈️🚀🛳"
    let defaultFontSize: CGFloat = 40
}


struct ScrollingEmojisView: View {
    let emojis: String
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(emojis.map { String($0) }, id: \.self) { emoji in
                    Text(emoji)
                        .onDrag { NSItemProvider(object: emoji as NSString) }
                }
            }
        }
    }
}









struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        EmojiArtDocumentView(document: EmojiArtDocument())
    }
}
