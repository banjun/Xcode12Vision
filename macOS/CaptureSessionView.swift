import SwiftUI

struct CaptureSessionView: NSViewRepresentable {
    let captureSession: CaptureSession

    func makeNSView(context: Context) -> NSView {
        .init()
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        captureSession.previewLayer?.videoGravity = .resizeAspect
        nsView.layer = captureSession.previewLayer
    }
}

//struct CaptureSessionView_Previews: PreviewProvider {
//    static var previews: some View {
//        CaptureSessionView(previewLayer: nil, recognizedLayers: [])
//    }
//}
