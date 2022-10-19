//
//  ViewController.swift
//  TRAudioTrimmer
//
//  Created by BCL-Device-11 on 17/10/22.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {
    
    @IBOutlet weak var trimView: TRAudioTrimmerView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let url = Bundle.main.url(forResource: "Aadat", withExtension: "mp3")
        let audioAsset = AVAsset(url: url!)
        trimView.asset = audioAsset
        trimView.delegate = self
    }
}

extension ViewController: TRAudioTrimmerViewDelegate {
    
    func didChangePositionBar(_ playerTime: CMTime) {
        
    }
    
    func positionBarStoppedMoving(_ playerTime: CMTime) {
        let startTime = trimView.startTime!.seconds
        let endTime = trimView.endTime!.seconds
        print("Start Time : ",startTime)
        print("END Time : ",endTime)
    }
}
