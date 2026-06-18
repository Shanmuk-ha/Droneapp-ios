import Flutter
import UIKit
import AVFoundation
import Photos

class VideoRecorder: NSObject {
    private var assetWriter: AVAssetWriter?
    private var videoInput: AVAssetWriterInput?
    private var pixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor?
    private var outputURL: URL?
    private var frameCount: Int64 = 0
    private let frameRate: Int32 = 10
    private var isRecording = false
    private var videoWidth = 640
    private var videoHeight = 480

    func startRecording(width: Int, height: Int) throws {
        videoWidth = width
        videoHeight = height
        frameCount = 0

        let cacheDir = FileManager.default.urls(
            for: .cachesDirectory, in: .userDomainMask).first!
        outputURL = cacheDir.appendingPathComponent(
            "drone_\(Int(Date().timeIntervalSince1970)).mp4")

        assetWriter = try AVAssetWriter(
            outputURL: outputURL!,
            fileType: .mp4)

        let settings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: width,
            AVVideoHeightKey: height,
            AVVideoCompressionPropertiesKey: [
                AVVideoAverageBitRateKey: 1_000_000,
                AVVideoMaxKeyFrameIntervalKey: frameRate,
            ]
        ]

        videoInput = AVAssetWriterInput(
            mediaType: .video, outputSettings: settings)
        videoInput!.expectsMediaDataInRealTime = true

        let attributes: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String:
                kCVPixelFormatType_32BGRA,
            kCVPixelBufferWidthKey as String: width,
            kCVPixelBufferHeightKey as String: height,
        ]

        pixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: videoInput!,
            sourcePixelBufferAttributes: attributes)

        assetWriter!.add(videoInput!)
        assetWriter!.startWriting()
        assetWriter!.startSession(
            atSourceTime: .zero)
        isRecording = true
    }

    func addFrame(jpegData: Data) {
        guard isRecording,
              let input = videoInput,
              input.isReadyForMoreMediaData,
              let adaptor = pixelBufferAdaptor,
              let image = UIImage(data: jpegData),
              let cgImage = image.cgImage else { return }

        let time = CMTime(
            value: frameCount,
            timescale: CMTimeScale(frameRate))

        var pixelBuffer: CVPixelBuffer?
        CVPixelBufferCreate(
            kCFAllocatorDefault,
            videoWidth, videoHeight,
            kCVPixelFormatType_32BGRA,
            [kCVPixelBufferCGImageCompatibilityKey: true,
             kCVPixelBufferCGBitmapContextCompatibilityKey: true]
                as CFDictionary,
            &pixelBuffer)

        guard let pb = pixelBuffer else { return }
        CVPixelBufferLockBaseAddress(pb, [])

        let ctx = CGContext(
            data: CVPixelBufferGetBaseAddress(pb),
            width: videoWidth,
            height: videoHeight,
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(pb),
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue |
                CGBitmapInfo.byteOrder32Little.rawValue)

        ctx?.draw(cgImage, in: CGRect(
            x: 0, y: 0,
            width: videoWidth, height: videoHeight))

        CVPixelBufferUnlockBaseAddress(pb, [])
        adaptor.append(pb, withPresentationTime: time)
        frameCount += 1
    }

    func stopRecording(completion: @escaping (String?) -> Void) {
        guard isRecording else {
            completion(nil)
            return
        }
        isRecording = false
        videoInput?.markAsFinished()
        assetWriter?.finishWriting { [weak self] in
            guard let self = self,
                  let url = self.outputURL else {
                completion(nil)
                return
            }
            self.saveToPhotoLibrary(url: url,
                completion: completion)
        }
    }

   private func saveToPhotoLibrary(
       url: URL,
       completion: @escaping (String?) -> Void) {

       if #available(iOS 14, *) {

           PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in

               guard status == .authorized ||
                     status == .limited else {
                   completion(nil)
                   return
               }

               PHPhotoLibrary.shared().performChanges({
                   let req = PHAssetCreationRequest.forAsset()
                   req.addResource(
                       with: .video,
                       fileURL: url,
                       options: nil)
               }) { success, error in
                   try? FileManager.default.removeItem(at: url)
                   completion(success ? url.path : nil)
               }
           }

       } else {

           PHPhotoLibrary.requestAuthorization { status in

               guard status == .authorized else {
                   completion(nil)
                   return
               }

               PHPhotoLibrary.shared().performChanges({
                   let req = PHAssetCreationRequest.forAsset()
                   req.addResource(
                       with: .video,
                       fileURL: url,
                       options: nil)
               }) { success, error in
                   try? FileManager.default.removeItem(at: url)
                   completion(success ? url.path : nil)
               }
           }
       }
   }
}