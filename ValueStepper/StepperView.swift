//
//  StepperView.swift
//  ValueStepper
//
//  Created by Alexx on 9/4/20.
//  Copyright © 2020 Alexx. All rights reserved.
//

import UIKit

enum ErrorKey {
    case incorrectSymbols, crossedMax, crossedMin, nonMultiple
}

struct Result {
    var valid: Bool
    var errorKey: ErrorKey?
    
    static func error(_ errorKey: ErrorKey) -> Result {
        return Result(valid: false, errorKey: errorKey)
    }
    
    static var ok: Result {
        return Result(valid: true, errorKey: nil)
    }
}

struct Decision {
    var allow: Bool
    var errorKey: ErrorKey?
    var replacement: String?
    
    static var ok = Decision(allow: true, errorKey: nil, replacement: nil)
    static func replacement(_ string: String) -> Self {
        return Decision(allow: false, errorKey: nil, replacement: string)
    }
    static func noReplacementError(_ errorKey: ErrorKey?) -> Self {
        return Decision(allow: false, errorKey: errorKey, replacement: nil)
    }
}

protocol StepperViewValidator {
    
    mutating func updateValues(from stepper: StepperView)
    
    func canStepUp(value: Double) -> Bool
    func canStepDown(value: Double) -> Bool
    
    func checkText(_ text: String?) -> Result
    func shouldReplace(text: String?, range: NSRange, with string: String) -> Decision
}

protocol StepperViewDelegate {
    func stepperView(_ stepperView: StepperView, gotError error: ErrorKey)
}

@IBDesignable
class StepperView: UIView, UITextFieldDelegate {
    
    private let stackView = UIStackView()
    
    private let plusButton = LongPressButton()
    private let minusButton = LongPressButton()
    
    private let textField = UITextField()
    
    private var textFieldWidthConstraint: NSLayoutConstraint?
    
    private var plusHeightConstraint: NSLayoutConstraint?
    private var plusWidthConstraint: NSLayoutConstraint?
    private var minusHeightConstraint: NSLayoutConstraint?
    private var minusWidthConstraint: NSLayoutConstraint?
    
    @IBInspectable var font: UIFont = UIFont.systemFont(ofSize: 16.0) {
        didSet {
            textField.font = font
        }
    }
    
    @IBInspectable var color: UIColor = .systemBlue {
        didSet {
            updateColor()
        }
    }
    
    @IBInspectable var spacing: CGFloat = 5.0 {
        didSet {
            stackView.spacing = spacing
        }
    }
    
    var validator: StepperViewValidator?
    
    var delegate: StepperViewDelegate?
    
    var placeholderValue: Double?
    
    @IBInspectable var value: Double {
        get {
            if let text = textField.text {
                return Double(text) ?? 0
            }
            textField.text = "\(limits.min ?? 0.0)"
            return limits.min ?? 0.0
        }
        set {
            textField.text = "\(newValue)".removeLastZeros().removeBeginningZeros()
        }
    }
    
    @IBInspectable var step: Double = 10 {
        didSet {
            validator?.updateValues(from: self)
        }
    }
    
    var limits: Limits = (nil, nil) {
        didSet {
            validator?.updateValues(from: self)
            updateState()
        }
    }
    
    var accelerationModifier = 1
    
    var isEditing: Bool = false
    
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonSetup()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonSetup()
    }
    
    convenience init() {
        self.init(frame: .zero)
    }
    
    func commonSetup() {
        setupLayout()
        
        stackView.alignment = .center
        
        textField.delegate = self
        textField.borderStyle = .none
        textField.textAlignment = .center
        
        plusButton.touchBegin = {_ in
            self.stepPlus()
        }
        plusButton.touchStep = {_ in
            self.stepPlus()
            self.accelerate()
        }
        plusButton.touchEnd = {_ in
            self.accelerationModifier = 1
        }
        minusButton.touchBegin = {_ in
            self.stepMinus()
        }
        minusButton.touchStep = {_ in
            self.stepMinus()
            self.accelerate()
        }
        minusButton.touchEnd = {_ in
            self.accelerationModifier = 1
        }
    }
    
    func setupLayout() {
        stackView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(stackView)
        stackView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        stackView.leftAnchor.constraint(equalTo: self.leftAnchor).isActive = true
        stackView.rightAnchor.constraint(equalTo: self.rightAnchor).isActive = true
        stackView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true

        stackView.addArrangedSubview(plusButton)
        stackView.addArrangedSubview(textField)
        stackView.addArrangedSubview(minusButton)
    }
    
    @IBInspectable var textFieldWidth: CGFloat = 0.0 {
        didSet {
            if textFieldWidth == 0.0 {
                textFieldWidthConstraint?.isActive = false
            } else if textFieldWidthConstraint != nil {
                textFieldWidthConstraint?.constant = textFieldWidth
                textFieldWidthConstraint?.isActive = true
            } else {
                textFieldWidthConstraint = textField.widthAnchor.constraint(equalToConstant: textFieldWidth)
                textFieldWidthConstraint?.isActive = true
            }
        }
    }
    
    @IBInspectable var buttonsSize: CGSize = .zero {
        didSet {
            if buttonsSize == .zero {
                plusHeightConstraint?.isActive = false
                plusWidthConstraint?.isActive = false
                minusHeightConstraint?.isActive = false
                minusWidthConstraint?.isActive = false
                return
            }
            if plusHeightConstraint != nil {
                plusHeightConstraint?.constant = buttonsSize.height
            } else {
                plusHeightConstraint = plusButton.heightAnchor.constraint(equalToConstant: buttonsSize.height)
            }
            if plusWidthConstraint != nil {
                plusWidthConstraint?.constant = buttonsSize.width
            } else {
                plusWidthConstraint = plusButton.widthAnchor.constraint(equalToConstant: buttonsSize.width)
            }
            if minusHeightConstraint != nil {
                minusHeightConstraint?.constant = buttonsSize.height
            } else {
                minusHeightConstraint = minusButton.heightAnchor.constraint(equalToConstant: buttonsSize.height)
            }
            if minusWidthConstraint != nil {
                minusWidthConstraint?.constant = buttonsSize.width
            } else {
                minusWidthConstraint = minusButton.widthAnchor.constraint(equalToConstant: buttonsSize.width)
            }
            plusHeightConstraint?.isActive = true
            plusWidthConstraint?.isActive = true
            minusHeightConstraint?.isActive = true
            minusWidthConstraint?.isActive = true
        }
    }
    
    @IBInspectable var plusImage: UIImage? {
        didSet {
            plusButton.setImage(plusImage, for: .normal)
        }
    }
    
    @IBInspectable var minusImage: UIImage? {
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
        value += step * Double(accelerationModifier)
        updateState()
    }
    
    func stepMinus() {
        value -= step * Double(accelerationModifier)
        updateState()
    }
    
    func abortTicking() {
        plusButton.cancelTouch()
        minusButton.cancelTouch()
        accelerationModifier = 1
        isEditing = false
    }
    
    func updateState() {
        guard let validator = validator else {return}
        plusButton.isEnabled = validator.canStepUp(value: value)
        minusButton.isEnabled = validator.canStepDown(value: value)
        let result = validator.checkText(textField.text)
        var text = textField.text
        if result.valid {
            text = text?.removeBeginningZeros().removeLastZeros()
            if text == "" {
                textField.text = "0"
            } else {
                textField.text = text
            }
        } else {
            delegate?.stepperView(self, gotError: result.errorKey!)
            switch result.errorKey {
                case .crossedMax:
                    value = limits.max!
                    abortTicking()
                case .crossedMin:
                    value = limits.min!
                    abortTicking()
                case .nonMultiple:
                    value -= value.truncatingRemainder(dividingBy: step)
                case .incorrectSymbols:
                    value = limits.min ?? 0
                default: break
            }
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        isEditing = true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        isEditing = false
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

extension String {
    func removeBeginningZeros() -> String {
        guard self.count > 1 else {return self}
        var text = self
        while text.first == "0" && text[text.index(self.startIndex, offsetBy: 1)] != "." {
            text.remove(at: text.startIndex)
        }
        return text
    }
    
    func removeLastZeros() -> String {
        var text = self
        guard let _ = text.range(of: ".") else {return text}
        while text.last == "0" {
            text.removeLast()
        }
        if text.last == "." {
            text.removeLast()
        }
        return text
    }
}