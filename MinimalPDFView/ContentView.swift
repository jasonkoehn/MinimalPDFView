//
//  ContentView.swift
//  MinimalPDFView
//
//  Created by Jason Koehn on 11/28/23.
//

import SwiftUI

struct ContentView: View {
    
    private let pdfUrl: URL = Bundle.main.url(forResource: "Jesus, Priceless Treasure", withExtension: "pdf")!
//    private let pdfUrl: URL = Bundle.main.url(forResource: "O Where Are the Reapers?", withExtension: "pdf")!
    
    @State var scale = 1.0
    @State var lastScale = 0.0
    
//    @State var anchorPoint: UnitPoint = UnitPoint(x: 0.5, y: 0.3456)
    
    @State var offset: CGSize = .zero
    @State var lastOffset: CGSize = .zero
    
    
    @State var images: [UIImage]?
    @State var image: UIImage?
    
    
    @State var viewWidth: CGFloat = 0
    @State var viewHeight: CGFloat = 0
    
    @State var imageWidth: CGFloat = 0
    @State var imageHeight: CGFloat = 0
    
    @State var frameWidth: CGFloat = 0
    @State var frameHeight: CGFloat = 0
    
    @State var allowableScrollOffset: CGFloat = 0
    
    @State var allowableExtraWidth: CGFloat = 0
    @State var allowableExtraHeight: CGFloat = 0
    
    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                if let image {
                    VStack {
                        Spacer()
                        Image(uiImage: image)
                            .resizable()
                            .frame(width: frameWidth, height: frameHeight)
                            .aspectRatio(contentMode: .fit)
                            .scaleEffect(scale)
                            //.scaleEffect(scale, anchor: anchorPoint)
                            .offset(offset)
                            .gesture(
                                MagnificationGesture(minimumScaleDelta: 0)
                                    .onChanged({ value in
                                        withAnimation(.interactiveSpring()) {
                                            scale = handleScaleChange(value)
                                        }
                                    })
                                    .onEnded({ _ in
                                        if scale < 1.0 {
                                            withAnimation(.interactiveSpring) {
                                                scale = 1.0
                                                offset.width = 0.0
                                                lastOffset.width = 0.0
                                                lastScale = scale
                                            }
                                            getAllowableExtraSize()
                                        } else {
                                            lastScale = scale
                                            getAllowableExtraSize()
                                        }
                                    })
                                    .simultaneously(
                                        with: DragGesture(minimumDistance: 0)
                                            .onChanged({ value in
                                                withAnimation(.interactiveSpring()) {
                                                    offset = handleOffsetChange(value.translation)
                                                }
                                            })
                                            .onEnded({ _ in
                                                withAnimation(.interactiveSpring) {
                                                    if (offset.height) > allowableExtraHeight {
                                                        offset.height = allowableExtraHeight
                                                    } else if (offset.height) < (allowableScrollOffset + -allowableExtraHeight) {
                                                        offset.height = (allowableScrollOffset + -allowableExtraHeight)
                                                    }
                                                    
                                                    lastOffset = offset
                                                }
                                            })
                                    )
                            )
                        Spacer()
                    }
                    .background(.blue)
                    .task {
                        viewWidth = geo.size.width
                        viewHeight = geo.size.height
                        let multiple = geo.size.width / imageWidth
                        frameWidth = (imageWidth * multiple)
                        frameHeight = (imageHeight * multiple)
                        if viewHeight < frameHeight {
                            allowableScrollOffset = (viewHeight - frameHeight)
                        }
                    }
                } else {
                    ProgressView()
                }
            }
        }
        .onAppear {
            images = convertPDFToImages(pdfUrl)
            renderImage()
        }
    }
    
    private var imageView: some View {
        ZStack {
            if let images {
                VStack {
                    ForEach(images, id: \.self) { image in
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    }
                }
            }
        }
    }
    
    @MainActor
    private func renderImage() {
        let renderer = ImageRenderer(content: imageView)
        renderer.scale = 6.0
        if let uiImage = renderer.uiImage {
            image = uiImage
            imageWidth = uiImage.size.width
            imageHeight = uiImage.size.height
        }
    }
    
    func getAllowableExtraSize() {
        let adjustedWidth = frameWidth * scale
        let adjustedHeight = frameHeight * scale
        
        allowableExtraWidth = (adjustedWidth - frameWidth) / 2
        allowableExtraHeight = (adjustedHeight - frameHeight) / 2
    }
    
    private func handleScaleChange(_ zoom: CGFloat) -> CGFloat {
        lastScale + zoom - (lastScale == 0 ? 0 : 1)
    }
    
    private func handleOffsetChange(_ offset: CGSize) -> CGSize {
        var newOffset: CGSize = .zero
        
        // Width
        if (offset.width + lastOffset.width) > allowableExtraWidth {
            newOffset.width = allowableExtraWidth
        } else if (offset.width + lastOffset.width) > -allowableExtraWidth {
            newOffset.width = offset.width + lastOffset.width
        } else {
            newOffset.width = -allowableExtraWidth
        }
        
        
        
        // Height
        newOffset.height = offset.height + lastOffset.height
        
        return newOffset
    }
    
    //    if (offset.height + lastOffset.height) > allowableExtraHeight {
    //        newOffset.height = allowableExtraHeight
    //    } else if (offset.height + lastOffset.height) > (allowableScrollOffset + -allowableExtraHeight) {
    //        newOffset.height = offset.height + lastOffset.height
    //    } else {
    //        newOffset.height = (allowableScrollOffset + -allowableExtraHeight)
    //    }
    
}


#Preview {
    ContentView()
}
