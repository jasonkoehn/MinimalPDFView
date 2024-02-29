//
//  TrackTouchesView.swift
//  MinimalPDFView
//
//  Created by Jason Koehn on 2/22/24.
//

import SwiftUI

struct MovedTouch: Equatable {
    var finger: Int
    var oldLocation: CGPoint
    var newLocation: CGPoint
}


struct TrackTouchesView: View {
    
    @State var touches: [MovedTouch] = []
    
    @State var location: CGSize = .zero
    @State var scale = 1.0
    @State var anchor: UnitPoint = .zero
    
    @State var testOffset: CGSize = .init(width: 200, height: 200)
    
    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                VStack {
                    Spacer()
                    ZStack {
                        
                        
                        Image("Photo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .offset(location)
                            .scaleEffect(scale, anchor: anchor)
                        
                        Circle()
                            .frame(width: 50)
                            .foregroundColor(.red)
                            .offset(testOffset)
                    }
                    .frame(width: geo.size.width, height: geo.size.width)
                    Spacer()
                }
                .overlay {
                    TouchesView(touches: $touches)
                }
            }
        }
        .onChange(of: touches) { _ in
            handleTouches(touches)
        }
    }
    
    func handleTouches(_ touches: [MovedTouch]) {
        if touches.count == 1 {
            getOffsetChange(touches.first!)
        } else if touches.count > 1 {
            getScale(touches)
        }
    }
    
    func getOffsetChange(_ touch: MovedTouch) {
        let xChange = (touch.newLocation.x - touch.oldLocation.x)
        let yChange = (touch.newLocation.y - touch.oldLocation.y)
        location.width += xChange
        location.height += yChange
    }
    
    func getScale(_ touches: [MovedTouch]) {
//        print(CGPointDistanceSquared(from: touches[0].newLocation, to: touches[1].newLocation))
        print(CGPointDistance(from: touches[0].newLocation, to: touches[1].newLocation))
        testOffset = getCenterPoint(from: touches[0].newLocation, to: touches[1].newLocation)
    }
    
    func CGPointDistance(from: CGPoint, to: CGPoint) -> CGFloat {
        return sqrt(CGPointDistanceSquared(from: from, to: to))
    }
    func CGPointDistanceSquared(from: CGPoint, to: CGPoint) -> CGFloat {
        return (from.x - to.x) * (from.x - to.x) + (from.y - to.y) * (from.y - to.y)
    }
    
    func getCenterPoint(from: CGPoint, to: CGPoint) -> CGSize {
        let xChange = from.x - to.x
        let yChange = from.y - to.y
        return .init(width: from.x + xChange, height: from.y + yChange)
    }
    
}


#Preview {
    TrackTouchesView()
}

struct TouchesView: UIViewRepresentable {
    
    //    var tappedCallback: (UITouch, CGPoint?) -> Void
    
    @Binding var touches: [MovedTouch]
    
    func makeUIView(context: UIViewRepresentableContext<TouchesView>) -> TouchesView.UIViewType {
        let v = UIView(frame: .zero)
        let gesture = NFingerGestureRecognizer(target: context.coordinator, touches: $touches)
        v.addGestureRecognizer(gesture)
        return v
    }
    
    func updateUIView(_ uiView: UIView, context: UIViewRepresentableContext<TouchesView>) {}
    
}

class NFingerGestureRecognizer: UIGestureRecognizer {
    
    var touchViews = [UITouch:CGPoint]()
    
    var fingers = [UITouch?](repeating: nil, count:5)
    
    @Binding var touches: [MovedTouch]
    
    init(target: Any?, touches: Binding<[MovedTouch]>) {
        self._touches = touches
        super.init(target: target, action: nil)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesBegan(touches, with: event)
        for touch in touches{
            let newLocation = touch.location(in: touch.view)
            for (index,finger)  in fingers.enumerated() {
                if finger == nil {
                    fingers[index] = touch
//                    print("BEGIN: finger \(index+1): x=\(newLocation.x) , y=\(newLocation.y)")
                    break
                }
            }
            touchViews[touch] = newLocation
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesMoved(touches, with: event)
        for touch in touches {
            let newLocation = touch.location(in: touch.view)
            let oldLocation = touchViews[touch]!
            for (index,finger) in fingers.enumerated() {
                if let finger = finger, finger == touch {
//                    print("MOVED: finger \(index+1): x=\(oldLocation.x) , y=\(oldLocation.y) -> x=\(newLocation.x) , y=\(newLocation.y)")
                    let newTouch: MovedTouch = MovedTouch(finger: index, oldLocation: oldLocation, newLocation: newLocation)
                    if let idx = self.touches.firstIndex(where: { $0.finger == newTouch.finger }) {
                        self.touches[idx] = newTouch
                    } else {
                        self.touches.append(newTouch)
                    }
                    break
                }
            }
            touchViews[touch] = newLocation
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesEnded(touches, with: event)
        for touch in touches {
            let oldLocation = touchViews[touch]!
            for (index,finger) in fingers.enumerated() {
                if let finger = finger, finger == touch {
                    fingers[index] = nil
                    if let idx = self.touches.firstIndex(where: { $0.finger == index }) {
                        self.touches.remove(at: idx)
                    }
//                    print("END: finger \(index+1): x=\(oldLocation.x) , y=\(oldLocation.y)")
                    break
                }
            }
            touchViews.removeValue(forKey: touch)
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesCancelled(touches, with: event)
        touchesEnded(touches, with: event)
    }
    
    
}
