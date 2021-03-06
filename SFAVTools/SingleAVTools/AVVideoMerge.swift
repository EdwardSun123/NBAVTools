//
//  AVVideoMerge.swift
//  SFAVTools
//
//  Created by 孙凡 on 17/5/5.
//  Copyright © 2017年 Edward. All rights reserved.
//

import UIKit
import AVFoundation

class AVVideoMerge {
    
    class func videoMerge(videoAsset assets: [AVAsset]) throws -> AVMutableComposition {
    
        let mixComposition = AVMutableComposition()
        
        var videoTrack: AVMutableCompositionTrack?
        var audioTrack: AVMutableCompositionTrack?
        
        var totalDuration: CMTime = kCMTimeZero
        
        for asset in assets {
            
            let timeRange = CMTimeRangeMake(kCMTimeZero, asset.duration)
            
            for assetVideoTrack in asset.tracks(withMediaType: AVMediaType.video) {
                
                if videoTrack == nil {
                    videoTrack = mixComposition.addMutableTrack(withMediaType: AVMediaType.video, preferredTrackID: kCMPersistentTrackID_Invalid)
                }
                
                do {
                    try videoTrack?.insertTimeRange(timeRange, of: assetVideoTrack, at: totalDuration)
                } catch {
                    throw error
                }
            }
            
            for assetAudioTrack in asset.tracks(withMediaType: AVMediaType.audio) {
                
                if audioTrack == nil {
                    audioTrack = mixComposition.addMutableTrack(withMediaType: AVMediaType.audio, preferredTrackID: kCMPersistentTrackID_Invalid)
                }
                
                do {
                    try audioTrack?.insertTimeRange(timeRange, of: assetAudioTrack, at: totalDuration)
                } catch {
                    throw error
                }
            }

            totalDuration = CMTimeAdd(totalDuration, asset.duration)
        }
     
        return mixComposition
    }

}
