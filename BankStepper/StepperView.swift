//
//  StepperView.swift
//  BankStepper
//
//  Created by Vlad on 9/4/20.
//  Copyright © 2020 Alexx. All rights reserved.
//

import UIKit

typealias Currency = Double

protocol PStepperValidator {
    var limits: Limits { get set }
    
    func canStepUp(value: Currency) -> Bool
    func canStepDown(value: Currency) -> Bool
    
    func checkText(_ text: String?) -> Validator.Result
    func shouldReplace(text: String?, range: NSRange, with string: String) -> Validator.Decision
}

protocol PStepperDelegate {
    func stepperView(_ stepperView: StepperView, gotError error: Validator.ErrorKey)
}

class StepperView: UIStackView, UITextFieldDelegate {
    
    private let stackView = UIStackView()
    
    private let plusButton = LongPressButton()
    private let minusButton = LongPressButton()
    
    private let textField = UITextField()
    
    var font: UIFont = UIFont.systemFont(ofSize: 16.0) {
        didSet {
            textField.font = font
        }
    }
    
    var color: UIColor = .systemBlue {
        didSet {
            updateColor()
        }
    }
    
    var validator: PStepperValidator?
    
    var delegate: PStepperDelegate?
    
    var placeholderValue: Currency?
    
    var value: Currency {
        get {
            return Currency(textField.text ?? "0") ?? 0
        }
        set {
            textField.text = "\(newValue)"
        }
    }
    
    var step: Currency = 10
    
    var accelerationModifier = 1
    
    var isEditing: Bool = false
    
    init() {
        super.init(frame: .zero)
        
        
        setupLayout()
        
        stackView.alignment = .center
        stackView.spacing = 5.0
        
        textField.delegate = self
        textField.borderStyle = .none
        textField.textAlignment = .center
        
        plusImage = UIImage(named: "plus")
        minusImage = UIImage(named: "minus")
        plusButton.setImage(UIImage(named: "plus"), for: .normal)
        minusButton.setImage(UIImage(named: "minus"), for: .normal)
        
        plusButton.touchBegin = {_ in
            self.stepPlus()
        }
        plusButton.touchTick = {_ in
            self.stepPlus()
            self.accelerate()
        }
        plusButton.touchEnd = {_ in
            self.accelerationModifier = 1
        }
        minusButton.touchBegin = {_ in
            self.stepMinus()
        }
        minusButton.touchTick = {_ in
            self.stepMinus()
            self.accelerate()
        }
        minusButton.touchEnd = {_ in
            self.accelerationModifier = 1
        }
        
        validator = Validator.Check(limits: (0, 200), step: step)
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupLayout() {
        stackView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(stackView)
        
        NSLayoutConstraint(item: stackView, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1.0, constant: 0.0).isActive = true
        NSLayoutConstraint(item: stackView, attribute: .left, relatedBy: .equal, toItem: self, attribute: .left, multiplier: 1.0, constant: 0.0).isActive = true
        NSLayoutConstraint(item: stackView, attribute: .right, relatedBy: .equal, toItem: self, attribute: .right, multiplier: 1.0, constant: 0.0).isActive = true
        NSLayoutConstraint(item: stackView, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1.0, constant: 0.0).isActive = true
        stackView.addArrangedSubview(plusButton)
        stackView.addArrangedSubview(textField)
        stackView.addArrangedSubview(minusButton)
        
        NSLayoutConstraint(item: plusButton, attribute: .height, relatedBy: .equal, toItem: plusButton, attribute: .width, multiplier: 1.0, constant: 0.0).isActive = true
        NSLayoutConstraint(item: minusButton, attribute: .height, relatedBy: .equal, toItem: minusButton, attribute: .width, multiplier: 1.0, constant: 0.0).isActive = true
        NSLayoutConstraint(item: plusButton, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 30.0).isActive = true
        NSLayoutConstraint(item: minusButton, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 30.0).isActive = true
    }
    
    var plusImage: UIImage? {
        didSet {
            plusButton.setImage(plusImage, for: .normal)
        }
    }
    
    var minusImage: UIImage? {
        didSet {
            minusButton.setImage(minusImage, for: .normal)
        }
    }
    
    func updateColor() {
        plusButton.tintColor = color
        minusButton.tintColor = color
        textField.textColor = color
    }

    func accelerate() {
        if accelerationModifier < 10 {
            accelerationModifier += 1
        }
    }
    
    func stepPlus() {
        value += step * Currency(accelerationModifier)
        updateState()
    }
    
    func stepMinus() {
        value -= step * Currency(accelerationModifier)
        updateState()
    }
    
    func abortTicking() {
        plusButton.abort()
        minusButton.abort()
        accelerationModifier = 1
        isEditing = false
    }
    
    func updateState() {
        guard let validator = validator else {return}
        plusButton.isEnabled = validator.canStepUp(value: value)
        minusButton.isEnabled = validator.canStepDown(value: value)
        let result = validator.checkText(textField.text)
        if !result.valid {
            delegate?.stepperView(self, gotError: result.errorKey!)
            switch result.errorKey {
                case .crossedMax:
                    value = validator.limits.max!
                    abortTicking()
                case .crossedMin:
                    value = validator.limits.min!
                    abortTicking()
                case .nonMultiple:
                    value -= value.truncatingRemainder(dividingBy: step)
                default: break
            }
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        updateState()
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let text = textField.text else { return false }
        guard let validator = validator else { return false }
        let result = validator.shouldReplace(text: text, range: range, with: string)
        if result.allow {
            return true
        } else if let error = result.errorKey {
            delegate?.stepperView(self, gotError: error)
            return false
        }
        textField.text = (text as NSString).replacingCharacters(in: range, with: result.replacement ?? "")
        return false
    }
}




