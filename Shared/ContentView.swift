import SwiftUI

struct ContentView: View {
    @StateObject var captureSession: CaptureSession = .init()

    var body: some View {
        VStack {
            Text("Hello, world!")
                .padding()
            Text("\(captureSession.recognizedPoints.filter {$0.point.confidence > 0.3}.count) points")
                .padding()
            ZStack {
                GeometryReader { geometry in
                    CaptureSessionView(captureSession: captureSession)
                        .edgesIgnoringSafeArea(/*@START_MENU_TOKEN@*/.all/*@END_MENU_TOKEN@*/)
                    ForEach(captureSession.recognizedPoints) {
                        let point = $0.point
                        VStack(spacing: -5) {
                            Rectangle()
                                .frame(width: 10, height: 10)
                                .foregroundColor(point.identifier.hasSuffix("TIP") ? .yellow : .blue)
                            Text(point.identifier)
                                .foregroundColor(.black)
                                .background(Color.white).opacity(0.5)
                        }
                        .position(x: CGFloat(point.x) * geometry.size.width,
                                  y: CGFloat(point.y) * geometry.size.height)
                        .opacity(Double(point.confidence))
                    }
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
