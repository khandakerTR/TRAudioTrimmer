//
//  TRAudioTrimmerView.swift
//  TRAudioTrimmer
//
//  Created by BCL-Device-11 on 17/10/22.
//

import UIKit
import AVFoundation

public protocol TRAudioTrimmerViewDelegate: AnyObject {
    func didChangePositionBar(_ playerTime: CMTime)
    func positionBarStoppedMoving(_ playerTime: CMTime)
}

class TRAudioTrimmerView: UIView {
    
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var trimView: UIView!
    @IBOutlet weak var leftHandleView: UIView!
    @IBOutlet weak var rightHandleView: UIView!
    @IBOutlet weak var positionBar: UIView!
    @IBOutlet weak var currentTimeLabel: UILabel!
    @IBOutlet weak var leftConstraint: NSLayoutConstraint!
    @IBOutlet weak var rightConstraint: NSLayoutConstraint!
    @IBOutlet weak var positionConstraint: NSLayoutConstraint!
    
    private let leftMaskView = UIView()
    private let rightMaskView = UIView()
    
    private var currentLeftConstraint: CGFloat = 0
    private var currentRightConstraint: CGFloat = 0
    
    public var asset: AVAsset?
    
    private var handleWidth: CGFloat {
        return self.leftHandleView.bounds.width
    }
    
    private var durationSize: CGFloat {
        return self.bounds.width - handleWidth * 2
    }
    
    private var positionBarTime: CMTime? {
        let barPosition = positionBar.frame.origin.x - handleWidth
        return getTime(from: barPosition)
    }
    
    public var startTime: CMTime? {
        let startPosition = leftHandleView.frame.origin.x
        return getTime(from: startPosition)
    }

    public var endTime: CMTime? {
        let endPosition = rightHandleView.frame.origin.x - handleWidth
        return getTime(from: endPosition)
    }
    
    public weak var delegate: TRAudioTrimmerViewDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        commonInit()
    }
    
    fileprivate func commonInit() {
        Bundle.main.loadNibNamed(String(describing:TRAudioTrimmerView.self), owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = self.bounds
        setupMaskView()
        setupGestures()
    }
    
    private func setupMaskView() {

        leftMaskView.backgroundColor = .black
        leftMaskView.alpha = 0.5
        leftMaskView.translatesAutoresizingMaskIntoConstraints = false
//        leftMaskView.layer.cornerRadius = 4.0
//        leftMaskView.layer.maskedCorners = [.layerMinXMaxYCorner,.layerMinXMinYCorner]
        insertSubview(leftMaskView, belowSubview: leftHandleView)

        leftMaskView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        leftMaskView.bottomAnchor.constraint(equalTo: trimView.bottomAnchor, constant: 0).isActive = true
        leftMaskView.topAnchor.constraint(equalTo: trimView.topAnchor, constant: 0).isActive = true
        leftMaskView.rightAnchor.constraint(equalTo: leftHandleView.leftAnchor).isActive = true

        rightMaskView.backgroundColor = .black
        rightMaskView.alpha = 0.5
//        rightMaskView.layer.cornerRadius = 4.0
//        rightMaskView.layer.maskedCorners = [.layerMaxXMinYCorner,.layerMaxXMaxYCorner]
        rightMaskView.translatesAutoresizingMaskIntoConstraints = false
        insertSubview(rightMaskView, belowSubview: rightHandleView)

        rightMaskView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        rightMaskView.bottomAnchor.constraint(equalTo: trimView.bottomAnchor, constant: 0).isActive = true
        rightMaskView.topAnchor.constraint(equalTo: trimView.topAnchor, constant: 0).isActive = true
        rightMaskView.leftAnchor.constraint(equalTo: rightHandleView.rightAnchor).isActive = true
    }
    
    private func setupGestures() {
        let leftPanGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(self.handlePanGesture))
        leftHandleView.addGestureRecognizer(leftPanGestureRecognizer)
        let rightPanGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(self.handlePanGesture))
        rightHandleView.addGestureRecognizer(rightPanGestureRecognizer)
    }
    
    @objc func handlePanGesture(_ gestureRecognizer: UIPanGestureRecognizer) {
        guard let view = gestureRecognizer.view, let superView = gestureRecognizer.view?.superview else { return }
        let isLeftGesture = view == leftHandleView
        switch gestureRecognizer.state {

        case .began:
            if isLeftGesture {
                currentLeftConstraint = leftConstraint!.constant
            } else {
                currentRightConstraint = -rightConstraint!.constant
            }
            updateSelectedTime(stoppedMoving: false)
        case .changed:
            let translation = gestureRecognizer.translation(in: superView)
            if isLeftGesture {
                updateLeftConstraint(with: translation)
            } else {
                updateRightConstraint(with: translation)
            }
            layoutIfNeeded()
            if let startTime = startTime, isLeftGesture {
                seek(to: startTime)
            } else if let endTime = endTime {
                seek(to: endTime)
            }
            updateSelectedTime(stoppedMoving: false)

        case .cancelled, .ended, .failed:
            updateSelectedTime(stoppedMoving: true)
        default: break
        }
    }
    
    public func seek(to time: CMTime) {
        if let newPosition = getPosition(from: time) {
            let offsetPosition = newPosition - leftHandleView.frame.origin.x
            let maxPosition = rightHandleView.frame.origin.x - (leftHandleView.frame.origin.x + handleWidth) - positionBar.frame.width
            let normalizedPosition = min(max(0, offsetPosition), maxPosition)
            positionConstraint?.constant = normalizedPosition
            positionConstraint?.isActive = true
            let currentTime = stringFromTimeInterval(sec: Int(time.seconds))
            currentTimeLabel.text = "\(currentTime)"
            layoutIfNeeded()
        }
    }

    private func stringFromTimeInterval(sec: Int) -> String {
        let seconds = sec % 60
        let minutes = (sec / 60) % 60
        return String(format: "%.2d:%.2d",minutes,seconds)
    }

    private func updateLeftConstraint(with translation: CGPoint) {
        let maxConstraint = max(rightHandleView.frame.origin.x - handleWidth, 0)
        let newConstraint = min(max(0, currentLeftConstraint + translation.x), maxConstraint)
        leftConstraint.isActive = true
        leftConstraint?.constant = newConstraint
    }

    private func updateRightConstraint(with translation: CGPoint) {
        let maxConstraint = min(2 * handleWidth - frame.width + leftHandleView.frame.origin.x, 0)
        let newConstraint = max(min(0, currentRightConstraint + translation.x), maxConstraint)
        rightConstraint.isActive = true
        rightConstraint?.constant = abs(newConstraint)
    }

    private func updateSelectedTime(stoppedMoving: Bool) {
        guard let playerTime = positionBarTime else {
            return
        }
        if stoppedMoving {
            delegate?.positionBarStoppedMoving(playerTime)
        } else {
            delegate?.didChangePositionBar(playerTime)
        }
    }
    
    private func getTime(from position: CGFloat) -> CMTime? {
        guard let asset = asset else {
            return nil
        }
        let normalizedRatio = max(min(1, position / durationSize), 0)
        let positionTimeValue = Double(normalizedRatio) * Double(asset.duration.value)
        return CMTime(value: Int64(positionTimeValue), timescale: asset.duration.timescale)
    }

    private func getPosition(from time: CMTime) -> CGFloat? {
        guard let asset = asset else {
            return nil
        }
        let timeRatio = CGFloat(time.value) * CGFloat(asset.duration.timescale) /
            (CGFloat(time.timescale) * CGFloat(asset.duration.value))
        return timeRatio * durationSize
    }
}
