//
//  AVAudioPlayer+.swift
//  TrainControl
//
//  Created by David Giovannini on 7/7/18.
//  Copyright © 2018 Object Computing Inc. All rights reserved.
//

import Foundation
import AVFoundation

extension AVAudioPlayer {

    static func playSound() -> AVAudioPlayer? {
        guard let url = Bundle.main.url(forResource: "glass break", withExtension: "mp3") else { return nil }
		
        do {
			try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback, mode: AVAudioSession.Mode.default)
            try AVAudioSession.sharedInstance().setActive(true)
			
            let player = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileType.mp3.rawValue)

            player.play()
			
            return player
			
        } catch let error {
            print(error.localizedDescription)
        }
        return nil
    }
}
