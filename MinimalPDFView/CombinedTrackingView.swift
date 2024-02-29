//
//  CombinedTrackingView.swift
//  MinimalPDFView
//
//  Created by Jason Koehn on 2/22/24.
//

import SwiftUI

struct CombinedTrackingView: View {
    
    private let pdfUrl: URL = Bundle.main.url(forResource: "Still-Guide-Me-Now-Official", withExtension: "pdf")!
    //private let pdfUrl: URL = Bundle.main.url(forResource: "One-Who-Knows-the-Stars", withExtension: "pdf")!
    
    @State var scale = 1.0
    @State var lastScale = 0.0
    
    
    @State var uiScale: CGFloat = 1.0
    @State var uiAnchorPoint: UnitPoint = .zero
    
    //@State var anchorPoint: UnitPoint = UnitPoint(x: 0.5, y: 0.3456)
    
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
                            //.scaleEffect(scale)
                            .scaleEffect(uiScale, anchor: uiAnchorPoint)
                            .offset(offset)
                            
                            .overlay {
                                GestureTransformView(width: $viewWidth, height: $viewHeight, scale: $uiScale, anchorPoint: $uiAnchorPoint)
                            }
                        Spacer()
                    }
                    .background(.teal)
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
}

#Preview {
    CombinedTrackingView()
}



struct GestureTransformView: UIViewRepresentable {
    @Binding var width: CGFloat
    @Binding var height: CGFloat
    @Binding var scale: CGFloat
    @Binding var anchorPoint: UnitPoint
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        
        let zoomRecognizer = UIPinchGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.zoom(_:)))
        
        zoomRecognizer.delegate = context.coordinator
        view.addGestureRecognizer(zoomRecognizer)
        context.coordinator.zoomRecognizer = zoomRecognizer
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
}

extension GestureTransformView {
    class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var parent: GestureTransformView
        var zoomRecognizer: UIPinchGestureRecognizer?
                
        init(_ parent: GestureTransformView){
            self.parent = parent
        }
        
        func setGestureStart(_ gesture: UIGestureRecognizer) {
            let point = gesture.location(in: gesture.view)
            parent.anchorPoint.x = point.x / parent.width
            parent.anchorPoint.y = point.y / parent.height
        }
        
        @objc func zoom(_ gesture: UIPinchGestureRecognizer) {
            switch gesture.state {
            case .began:
                setGestureStart(gesture)
                break
            case .changed:
                applyZoom(gesture)
                break
            case .cancelled:
                fallthrough
            case .ended:
                applyZoom(gesture)
//                zoomRecognizer?.scale = 1
            default:
                break
            }
        }
        
        func applyZoom(_ gesture: UIGestureRecognizer) {
            parent.scale = zoomRecognizer?.scale ?? 1
            let point = gesture.location(in: gesture.view)
            print(point.x)
            print(parent.width)
            parent.anchorPoint.x = point.x / parent.width
            parent.anchorPoint.y = point.y / parent.height
        }
    }
}
