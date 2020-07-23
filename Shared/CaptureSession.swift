import AVFoundation
import Vision

final class CaptureSession: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    private let session = AVCaptureSession()
    @Published var previewLayer: AVCaptureVideoPreviewLayer?
    private let videoProcessingQueue = DispatchQueue(label: "videoProcessingQueue", qos: .userInteractive)

    struct RecognizedHands {
        var hands: [Hand]
        struct Hand {
            var handIdentifier: UUID
            var points: [VNRecognizedPoint]
        }

        var identifiablePoints: [IdentifiablePoint] {
            hands.flatMap { hand in
                hand.points.map { p in
                    IdentifiablePoint(handIdentifier: hand.handIdentifier, point: p)
                }
            }
        }

        struct IdentifiablePoint: Identifiable {
            var handIdentifier: UUID
            var point: VNRecognizedPoint
            var id: ObjectIdentifier {.init((handIdentifier.uuidString + point.identifier) as NSString)}
        }
    }

    private var recognizedHands: RecognizedHands = .init(hands: []) {
        didSet {
            recognizedPoints = recognizedHands.identifiablePoints
        }
    }
    @Published var recognizedPoints: [RecognizedHands.IdentifiablePoint] = []

    override init() {
        super.init()

        let frontCamera = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: .front).devices.first!
        session.addInput(try! AVCaptureDeviceInput(device: frontCamera))
        let output = AVCaptureVideoDataOutput()
        output.setSampleBufferDelegate(self, queue: videoProcessingQueue)
        output.alwaysDiscardsLateVideoFrames = true
//        output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)]
        session.addOutput(output)
        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        session.startRunning()
    }

    let handPoseRequest: VNDetectHumanHandPoseRequest = {
        let r = VNDetectHumanHandPoseRequest()
        r.maximumHandCount = 2
        return r
    }()

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        var hands: RecognizedHands?
        defer {
            DispatchQueue.main.async {
                // NSLog("%@", "observed \(hands.hands.count) hands and \(hands.identifiablePoints.count) points")
                self.recognizedHands = hands ?? .init(hands:  [])
            }
        }

        let handler = VNImageRequestHandler(cmSampleBuffer: sampleBuffer, orientation: {
            switch (connection.videoOrientation, connection.isVideoMirrored) {
            case (.portrait, false): return .downMirrored // MBP front camera
            case (.portrait, true): return .down
            case (.portraitUpsideDown, false): return .upMirrored
            case (.portraitUpsideDown, true): return .up
            case (.landscapeRight, false): return .right
            case (.landscapeRight, true): return .rightMirrored
            case (.landscapeLeft, false): return .left // iPhone true depth front camera
            case (.landscapeLeft, true): return .leftMirrored
            @unknown default: return .up
            }
        }(), options: [:])
        do {
            try handler.perform([handPoseRequest])
            let observations = handPoseRequest.results as? [VNRecognizedPointsObservation] ?? []
            guard !observations.isEmpty else { return }

            hands = RecognizedHands(hands: try observations.map {
                RecognizedHands.Hand(handIdentifier: $0.uuid, points: [
                    try $0.recognizedPoints(forGroupKey: .handLandmarkRegionKeyThumb).values,
                    try $0.recognizedPoints(forGroupKey: .handLandmarkRegionKeyIndexFinger).values,
                    try $0.recognizedPoints(forGroupKey: .handLandmarkRegionKeyMiddleFinger).values,
                    try $0.recognizedPoints(forGroupKey: .handLandmarkRegionKeyRingFinger).values,
                    try $0.recognizedPoints(forGroupKey: .handLandmarkRegionKeyLittleFinger).values,
                ].flatMap {$0})
            })
        } catch {
            NSLog("%@", "handPoseRequest failed: \(String(describing: error))")
        }
    }
}
