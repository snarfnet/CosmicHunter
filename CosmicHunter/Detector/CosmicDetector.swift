import Foundation
import AVFoundation
import CoreVideo
import UIKit

/// Detects cosmic-ray / muon strikes on the covered camera CMOS sensor.
/// Same hot-pixel technique as a smartphone particle detector: with the lens
/// covered (dark frame), an ionizing particle deposits charge and lights up
/// one or a few pixels far above the sensor noise floor.
final class CosmicDetector: NSObject, ObservableObject {
    @Published var isRunning = false
    @Published var hitsPerMin: Double = 0        // sliding-window rate
    @Published var totalHits: Int = 0            // this session
    @Published var lastEventAt: Date?
    @Published var noiseFloor: Double = 0
    @Published var isCalibrating = false
    @Published var permissionDenied = false
    @Published var frameBrightness: Double = 0

    var onHit: ((Int) -> Void)?

    private let session = AVCaptureSession()
    private let queue = DispatchQueue(label: "cosmic.capture")
    private var device: AVCaptureDevice?

    private let lumaThreshold: UInt8 = 245
    private var eventTimes: [Date] = []          // last 60s of hit timestamps

    private var calibrationSamples: [Int] = []
    private var calibrationDeadline: Date?

    // MARK: lifecycle

    func start() {
        AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
            guard let self else { return }
            DispatchQueue.main.async {
                if granted {
                    self.permissionDenied = false
                    self.configureAndRun()
                } else {
                    self.permissionDenied = true
                }
            }
        }
    }

    func stop() {
        queue.async { [weak self] in
            guard let self else { return }
            if self.session.isRunning { self.session.stopRunning() }
        }
        DispatchQueue.main.async {
            self.isRunning = false
            self.isCalibrating = false
        }
    }

    func calibrate() {
        DispatchQueue.main.async {
            self.calibrationSamples = []
            self.calibrationDeadline = Date().addingTimeInterval(6)
            self.isCalibrating = true
        }
    }

    private func configureAndRun() {
        queue.async { [weak self] in
            guard let self else { return }
            self.session.beginConfiguration()
            self.session.sessionPreset = .vga640x480

            self.session.inputs.forEach { self.session.removeInput($0) }
            self.session.outputs.forEach { self.session.removeOutput($0) }

            guard let dev = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
                  let input = try? AVCaptureDeviceInput(device: dev),
                  self.session.canAddInput(input) else {
                self.session.commitConfiguration()
                return
            }
            self.device = dev
            self.session.addInput(input)

            let output = AVCaptureVideoDataOutput()
            output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String:
                                    kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange]
            output.alwaysDiscardsLateVideoFrames = true
            output.setSampleBufferDelegate(self, queue: self.queue)
            if self.session.canAddOutput(output) { self.session.addOutput(output) }

            self.session.commitConfiguration()
            self.configureForDarkCapture(dev)
            self.session.startRunning()

            DispatchQueue.main.async {
                self.isRunning = true
                self.totalHits = 0
                self.eventTimes = []
                self.calibrate()
            }
        }
    }

    private func configureForDarkCapture(_ dev: AVCaptureDevice) {
        do {
            try dev.lockForConfiguration()
            if dev.isFocusModeSupported(.locked) { dev.focusMode = .locked }
            let dur = CMTime(value: 1, timescale: 30)
            let iso = min(max(400, dev.activeFormat.minISO), dev.activeFormat.maxISO)
            dev.setExposureModeCustom(duration: dur, iso: iso, completionHandler: nil)
            if dev.isWhiteBalanceModeSupported(.locked) { dev.whiteBalanceMode = .locked }
            dev.unlockForConfiguration()
        } catch {}
    }

    // MARK: analysis

    private func analyze(_ pixelBuffer: CVPixelBuffer) {
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }

        guard let base = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0) else { return }
        let width = CVPixelBufferGetWidthOfPlane(pixelBuffer, 0)
        let height = CVPixelBufferGetHeightOfPlane(pixelBuffer, 0)
        let stride = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 0)
        let ptr = base.assumingMemoryBound(to: UInt8.self)

        var hot = 0
        var brightnessAccum: UInt64 = 0
        var sampleCount = 0
        let step = 4
        let thr = lumaThreshold

        var y = 1
        while y < height - 1 {
            let row = y * stride
            let up = (y - 1) * stride
            var x = 1
            while x < width - 1 {
                let v = ptr[row + x]
                if v >= thr {
                    // new connected component if left & up neighbours are below threshold
                    if ptr[row + x - 1] < thr && ptr[up + x] < thr { hot += 1 }
                }
                if (x % step == 0) && (y % step == 0) {
                    brightnessAccum += UInt64(v)
                    sampleCount += 1
                }
                x += 1
            }
            y += 1
        }

        let avgBright = sampleCount > 0 ? Double(brightnessAccum) / Double(sampleCount) : 0
        DispatchQueue.main.async { self.handle(hotCount: hot, brightness: avgBright) }
    }

    private func handle(hotCount: Int, brightness: Double) {
        frameBrightness = brightness

        if isCalibrating {
            calibrationSamples.append(hotCount)
            if let dl = calibrationDeadline, Date() >= dl {
                let avg = calibrationSamples.isEmpty ? 0 :
                    Double(calibrationSamples.reduce(0, +)) / Double(calibrationSamples.count)
                noiseFloor = avg
                isCalibrating = false
            }
            return
        }

        // subtract noise floor; only clear excess counts as particle hits
        let excess = Double(hotCount) - noiseFloor
        guard excess >= 1 else { pruneWindow(); return }

        let now = Date()
        let n = Int(excess.rounded())
        for _ in 0..<n { eventTimes.append(now) }
        totalHits += n
        lastEventAt = now
        onHit?(n)

        pruneWindow()
    }

    private func pruneWindow() {
        let cutoff = Date().addingTimeInterval(-60)
        eventTimes.removeAll { $0 < cutoff }
        hitsPerMin = Double(eventTimes.count)
    }

    // MARK: screenshot demo

    func loadDemoState() {
        isRunning = true
        hitsPerMin = 7
        totalHits = 342
        noiseFloor = 0.4
        frameBrightness = 3.2
        lastEventAt = Date()
    }
}

extension CosmicDetector: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        guard let pb = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        analyze(pb)
    }
}
