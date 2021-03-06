//
//  NBChanger.swift
//  SFAVTools
//
//  Created by 孙凡 on 2017/7/2.
//  Copyright © 2017年 Edward. All rights reserved.
//

import AVFoundation
import UIKit

public class NBChanger {
    
    fileprivate let asset: AVAsset
    fileprivate var mutableComposition: AVMutableComposition
    fileprivate var mutableVideoComposition: AVMutableVideoComposition
    fileprivate var videoTransform: CGAffineTransform = .identity
    fileprivate var videoRenderSize: CGSize = CGSize.zero
    fileprivate var resolutionMode: String = AVAssetExportPresetHighestQuality
    fileprivate var exportSession: AVAssetExportSession?
    fileprivate var videoAudioMix: AVMutableAudioMix?
    fileprivate var videoMode: AVFileType = AVFileType.mov
    fileprivate var videoFPS: Float = 30
    
    init(_ avAsset: AVAsset) {
        asset = avAsset
        mutableComposition = AVMutableComposition()
        mutableVideoComposition = AVMutableVideoComposition()
        initProperties()
    }
    
    private func initProperties() {
        
        mutableComposition = getMutableComposition(asset)
        videoTransform = getDefultTransform()
        videoRenderSize = getDefultRenderSize()
        videoFPS = getDefultFPS()
    }
    
    fileprivate func getMutableComposition(_ asset: AVAsset, timeRange: CMTimeRange? = nil) -> AVMutableComposition {
        var videoTrack: AVMutableCompositionTrack?
        var audioTrack: AVMutableCompositionTrack?
        
        let mixComposition = AVMutableComposition()
        
        let _timeRange = timeRange ?? CMTimeRangeMake(kCMTimeZero, asset.duration)
        
        for assetVideoTrack in asset.tracks(withMediaType: AVMediaType.video) {
            
            if videoTrack == nil {
                videoTrack = mixComposition.addMutableTrack(withMediaType: AVMediaType.video, preferredTrackID: kCMPersistentTrackID_Invalid)
            }
            
            do {
                try videoTrack?.insertTimeRange(_timeRange, of: assetVideoTrack, at: kCMTimeZero)
            } catch {
                
            }
        }
        
        for assetAudioTrack in asset.tracks(withMediaType: AVMediaType.audio) {
            
            if audioTrack == nil {
                audioTrack = mixComposition.addMutableTrack(withMediaType: AVMediaType.audio, preferredTrackID: kCMPersistentTrackID_Invalid)
            }
            
            do {
                try audioTrack?.insertTimeRange(_timeRange, of: assetAudioTrack, at: kCMTimeZero)
            } catch {
                
            }
        }
        
        return mixComposition
    }
    
    private func getDefultRenderSize() -> CGSize {
        guard let videoTrack = asset.tracks(withMediaType: AVMediaType.video).first else {
            return CGSize.zero
        }
        return videoTrack.naturalSize
    }
    
    private func getDefultTransform() -> CGAffineTransform {
        guard let videoTrack = asset.tracks(withMediaType: AVMediaType.video).first else {
            return CGAffineTransform.identity
        }
        return videoTrack.preferredTransform
    }
    
    private func getDefultFPS() -> Float {
        guard let videoTrack = asset.tracks(withMediaType: AVMediaType.video).first else {
            return 30
        }
        return videoTrack.nominalFrameRate
    }
}

//MARK: VideoProcess
extension NBChanger {
    
    @discardableResult func resolutionMode(_ mode: String) -> NBChanger {
        
        resolutionMode = mode
        
        return self
    }
    
    @discardableResult func fps(_ fps: Float) -> NBChanger {
        
        videoFPS = fps
        
        return self
    }
    
    @discardableResult func videoMode(_ mode: AVFileType) -> NBChanger {
        
        videoMode = mode
        
        return self
    }
    
    @discardableResult func rotate(_ angle: Double) -> NBChanger {
        
        _rotate(angle)
        
        return self
    }
    
    @discardableResult func speed(_ speedMultiple: Double) -> NBChanger {
        
        _speed(speedMultiple)
        
        return self
    }
    
    @discardableResult func trim(progressRange range: Range<Double>) -> NBChanger {
        
        _trim(progressRange: range)
        
        return self
    }
    
    @discardableResult func stretchRender(_ size: CGSize) -> NBChanger {
        
        _stretch(renderSize: videoRenderSize, toSize: size)
        
        return self
    }
    
    @discardableResult func background(_ image: CGImage) -> NBChanger {
        
        _background(image)
        
        return self
    }
    
    @discardableResult func add(_ assets: [AVAsset]) -> NBChanger {
        
        _add(assets)
        
        return self
    }
    
    @discardableResult func insert(_ audio: AVAsset) -> NBChanger {
        
        _insert(audio: audio)
        
        return self
    }
    
    @discardableResult func watermarks(_ watermarks: [CALayer]) -> NBChanger {
        
        _watermark(watermarks)
        
        return self
    }
}

//MAKR: Private VideoProcess
extension NBChanger {
    
    fileprivate func processMutableVideoComposition() {
        
        guard let videoTrack = mutableComposition.tracks(withMediaType: AVMediaType.video).first else {
            return
        }
        
        var instruction: AVMutableVideoCompositionInstruction
        var layerInstruction: AVMutableVideoCompositionLayerInstruction
        instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRange(start: kCMTimeZero, duration: mutableComposition.duration)
        layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack)
        layerInstruction.setTransform(videoTransform, at: kCMTimeZero)
        instruction.layerInstructions = [layerInstruction]
        
        mutableVideoComposition.renderSize = videoRenderSize
        mutableVideoComposition.frameDuration = CMTime(value: CMTimeValue(1), timescale: CMTimeScale(videoFPS))
        mutableVideoComposition.instructions = [instruction]
    }
    
    fileprivate func _add(_ assets: [AVAsset]) {
        
        var totalDuration: CMTime = mutableComposition.duration
        
        for asset in assets {
            
            let timeRange = CMTimeRangeMake(kCMTimeZero, asset.duration)
            
            var videoTrack: AVMutableCompositionTrack? = mutableComposition.tracks(withMediaType: AVMediaType.video).first
            var audioTrack: AVMutableCompositionTrack? = mutableComposition.tracks(withMediaType: AVMediaType.audio).first
            
            for assetVideoTrack in asset.tracks(withMediaType: AVMediaType.video) {
                
                if videoTrack == nil {
                    videoTrack = mutableComposition.addMutableTrack(withMediaType: AVMediaType.video, preferredTrackID: kCMPersistentTrackID_Invalid)
                }
                
                do {
                    try videoTrack?.insertTimeRange(timeRange, of: assetVideoTrack, at: totalDuration)
                } catch {
                }
            }
            
            for assetAudioTrack in asset.tracks(withMediaType: AVMediaType.audio) {
                
                if audioTrack == nil {
                    audioTrack = mutableComposition.addMutableTrack(withMediaType: AVMediaType.audio, preferredTrackID: kCMPersistentTrackID_Invalid)
                }
                
                do {
                    try audioTrack?.insertTimeRange(timeRange, of: assetAudioTrack, at: totalDuration)
                } catch {
                }
            }
            
            totalDuration = CMTimeAdd(totalDuration, asset.duration)
        }
        
    }
    
    fileprivate func _rotate(_ angle: Double) {
        
        let _angle = Double(Int64(fabs(angle)) % 360)
        let degree: CGFloat = Degree(_angle)
        //transform processing
        videoTransform = videoTransform.rotated(by: CGFloat(degree))
        let applySize: CGSize = videoRenderSize.applying(videoTransform)
        let absWidth: CGFloat = CGFloat(fabs(Double(applySize.width)))
        let absHeight: CGFloat = CGFloat(fabs(Double(applySize.height)))
        let tx: CGFloat
        let ty: CGFloat
        if applySize.width >= 0 {
            tx = 0
        } else {
            tx = absWidth
        }
        if applySize.height >= 0 {
            ty = 0
        } else {
            ty = absHeight
        }
        videoTransform.tx = tx
        videoTransform.ty = ty
        videoRenderSize = CGSize(width: absWidth, height: absHeight)
    }
    
    fileprivate func _stretch(renderSize fromSize : CGSize, toSize: CGSize) {
        
        let renderW: CGFloat
        let renderH: CGFloat
        let screenWidth: CGFloat = UIScreen.main.bounds.size.width
        let screenHeight: CGFloat = UIScreen.main.bounds.size.height
        if (fromSize.width/fromSize.height) >= (screenWidth/screenHeight) {
            renderW = fromSize.width
            renderH = fromSize.width / toSize.width * toSize.height
        } else {
            renderH = fromSize.height
            renderW = fromSize.height / toSize.height * toSize.width
        }
        
        
        let tx = (renderW - fromSize.width) * 0.5
        let ty = (renderH - fromSize.height) * 0.5
        
        videoTransform.tx = tx + videoTransform.tx
        videoTransform.ty = ty + videoTransform.ty
        
        videoRenderSize = CGSize(width: renderW, height: renderH)
        
    }
    
    fileprivate func _background(_ image: CGImage) {
        
        guard let videoTrack = mutableComposition.tracks(withMediaType: AVMediaType.video).first else {
            return
        }
        
        let applySize = videoTrack.naturalSize.applying(videoTransform)
        let absWidth = CGFloat(fabs(Double(applySize.width)))
        let absHeight = CGFloat(fabs(Double(applySize.height)))
        
        //Get parm
        let naturalSize = CGSize(width: absWidth, height: absHeight)
        let renderSize = videoRenderSize
        let maskX: CGFloat = (renderSize.width - absWidth) * 0.5
        let maskY: CGFloat = (renderSize.height - absHeight) * 0.5
        let maskPoint = CGPoint(x: maskX, y: maskY)
        
        //Set layers
        let parentLayer = CALayer()
        parentLayer.frame = CGRect(x: 0, y: 0, width: renderSize.width, height: renderSize.height)
        
        let imageLayer = CALayer()
        imageLayer.frame = parentLayer.bounds
        imageLayer.contents = image
        
        let videoLayer = CALayer()
        videoLayer.frame = CGRect(x: 0, y: 0, width: renderSize.width, height: renderSize.height)
        
        let shapeLayer = CAShapeLayer()
        let aPath = UIBezierPath(rect: CGRect(origin: maskPoint, size: naturalSize))
        shapeLayer.path = aPath.cgPath
        videoLayer.mask = shapeLayer
        
        videoLayer.setNeedsDisplay()
        
        parentLayer.addSublayer(imageLayer)
        parentLayer.addSublayer(videoLayer)
        
        mutableVideoComposition.animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: videoLayer, in: parentLayer)
    }
    
    fileprivate func _trim(progressRange range: Range<Double>) {
        
        let rangeStart = range.lowerBound <= 0 ? 0 : range.lowerBound
        let rangeEnd = range.upperBound >= 1 ? 1 : range.upperBound
        
        if rangeStart >= rangeEnd {
            assertionFailure("NBAsset:_trim(progressRange range: Range<Double>): trim range during can not small than 0.")
            return
        }
        
        let videoDuring = CMTimeGetSeconds(asset.duration)
        let timeScale = asset.duration.timescale
        
        let startIntervel = videoDuring * rangeStart
        let endIntervel = videoDuring * rangeEnd
        
        let startTime = CMTime(seconds: startIntervel, preferredTimescale: timeScale)
        let endTime = CMTime(seconds: endIntervel, preferredTimescale: timeScale)
        
        let timeRange = CMTimeRange(start: startTime, end: endTime)
        
        mutableComposition = getMutableComposition(mutableComposition, timeRange: timeRange)
    }
    
    fileprivate func _speed(_ speedMultiple: Double) {
        
        let timeRange = CMTimeRangeMake(kCMTimeZero, mutableComposition.duration)
        let scaleTimeValue = Double(mutableComposition.duration.value)/speedMultiple
        let scaleTime = CMTime(value: CMTimeValue(scaleTimeValue), timescale: mutableComposition.duration.timescale)
        
        for videoTrack in mutableComposition.tracks(withMediaType: AVMediaType.video) {
            videoTrack.scaleTimeRange(timeRange, toDuration: scaleTime)
        }
        
        for audioTrack in mutableComposition.tracks(withMediaType: AVMediaType.audio) {
            audioTrack.scaleTimeRange(timeRange, toDuration: scaleTime)
        }
    }
    
    fileprivate func _watermark(_ watermarks: [CALayer]) {
        
        let renderSize = videoRenderSize
        
        let parentLayer = CALayer()
        parentLayer.frame = CGRect(x: 0, y: 0, width: renderSize.width, height: renderSize.height)
        
        let videoLayer = CALayer()
        videoLayer.frame = parentLayer.bounds
        
        let watermarkLayer = CALayer()
        watermarkLayer.frame = parentLayer.bounds
        
        parentLayer.addSublayer(videoLayer)
        parentLayer.addSublayer(watermarkLayer)
        
        for watermark in watermarks {
            watermarkLayer.addSublayer(watermark)
        }
        
        mutableVideoComposition.animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: videoLayer, in: parentLayer)
    }
    
    fileprivate func _insert(audio: AVAsset) {
        
        let timeRange = CMTimeRangeMake(kCMTimeZero, mutableComposition.duration)
        
        var audioTrack: AVMutableCompositionTrack? = mutableComposition.tracks(withMediaType: AVMediaType.audio).first
        
        for assetAudioTrack in audio.tracks(withMediaType: AVMediaType.audio) {
            if audioTrack == nil {
                audioTrack = mutableComposition.addMutableTrack(withMediaType: AVMediaType.audio, preferredTrackID: kCMPersistentTrackID_Invalid)
            }
            do {
                try audioTrack?.insertTimeRange(timeRange, of: assetAudioTrack, at: kCMTimeZero)
            } catch {
            }
        }
    }
}
