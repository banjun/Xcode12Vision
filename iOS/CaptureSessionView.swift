import SwiftUI

struct CaptureSessionView: UIViewRepresentable {
    let captureSession: CaptureSession

    func makeUIView(context: Context) -> some UIView {
        UIView()
    }

    func updateUIView(_ uiView: UIViewType, context: Context) {
        guard let previewLayer = captureSession.previewLayer else {
            // TODO: remove
            return
        }

        previewLayer.frame = uiView.bounds
        uiView.layer.addSublayer(previewLayer)
    }
}

struct CaptureSessionView_Previews: PreviewProvider {
    static var previews: some View {
        CaptureSessionView(captureSession: .init())
    }
}
