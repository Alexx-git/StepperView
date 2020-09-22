//
//  LongPressButton.swift
//  ValueStepper
//
//  Created by Alexx on 9/5/20.
//  Copyright © 2020 Alexx. All rights reserved.
//

import UIKit


class LongPressButton: UIButton {
    
    typealias Handler = (UIButton) -> ()
    
    var touchBegin: Handler?
    
    var touchStep: Handler?
    
    var touchEnd: Handler?
    
    private var timer: Timer?
    
    private let gestureRecognizer = UILongPressGestureRecognizer()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        gestureRecognizer.addTarget(self, action: #selector(stateChanged))
        self.addGestureRecognizer(gestureRecognizer)
        self.addTarget(self, action: #selector(tap), for: .touchUpInside)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func cancelTouch() {
        timer?.invalidate()
        isHighlighted = false
    }
    
    @objc func tap() {
        touchBegin?(self)
    }
    
    @objc func stateChanged() {
        switch gestureRecognizer.state {
            case .began:
                touchBegin?(self)
                self.isHighlighted = true
                timer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true, block: {_ in
                    self.isHighlighted = true
                    self.touchStep?(self)
                })
            case .ended, .cancelled:
                cancelTouch()
                touchEnd?(self)
            default: break
        }
    }
    
    deinit {
        cancelTouch()
    }

}
