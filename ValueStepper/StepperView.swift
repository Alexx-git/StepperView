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
    static func replacement(_ string: String) -> Decision {
        return Decision(allow: false, errorKey: nil, replacement: string)
    }
    static func noReplacementError(_ errorKey: ErrorKey?) -> Decision {
        return Decision(allow: false, errorKey: errorKey, replacement: nil)
    }
}

protocol StepperViewValidator {
    
    func updateValues(from stepper: StepperView)
    
    func canStepUp(value: Double) -> Bool
    func canStepDown(value: Double) -> Bool
    
    func checkText(_ text: String?) -> Result
    func checkValue(_ value: Double) -> Result
    func shouldReplace(text: String?, range: NSRange, with string: String) -> Decision
}

protocol StepperViewDelegate {
    func stepperView(_ stepperView: StepperView, hasUpdatedWith result: Result)
}

@IBDesignable
class StepperView: UIView, UITextFieldDelegate {
    
    private let stackView = UIStackView()
    
    private let plusButton = LongPressButton()
    private let minusButton = LongPressButton()
    
    private let textField = UITextField()
    
    private var plusHeightConstraint: NSLayoutConstraint?
    private var plusWidthConstraint: NSLayoutConstraint?
    private var minusHeightConstraint: NSLayoutConstraint?
    private var minusWidthConstraint: NSLayoutConstraint?
    
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
    
    @IBInspectable var font: UIFont = UIFont.systemFont(ofSize: 16.0) {
        didSet {
            textField.font = font
        }
    }
    
    @IBInspectable var textColor: UIColor = .black {
        didSet {
            textField.textColor = textColor
            guard textField.defaultTextAttributes[.foregroundColor] != nil  else {return}
            textField.defaultTextAttributes[.foregroundColor] = textColor
        }
    }
    
    @IBInspectable var value: Double {
        get {
            if let text = textField.text?.removingComas() {
                return Double(text) ?? limits.min ?? 0.0
            }
            textField.text = string(from: limits.min ?? 0.0)
            return limits.min ?? 0.0
        }
        set {
            updateButtons()
            let response = validator.checkValue(newValue)
            if response.valid {
                textField.text = string(from: newValue)
            } else {
                textField.text = string(from: correctValue(newValue, error: response.errorKey!))
            }
            
        }
    }
    
    @IBInspectable var step: Double = 10 {
        didSet {
            maximumFractionDigits = step.fractionDigits()
            validator.updateValues(from: self)
            updateState()
        }
    }
    
    var limits: Limits = (nil, nil) {
        didSet {
            validator.updateValues(from: self)
            updateState()
        }
    }
    
    var validator: StepperViewValidator = Validator() {
        didSet {
            validator.updateValues(from: self)
        }
    }
    
    var delegate: StepperViewDelegate?
    
    var formatter: NumberFormatter = NumberFormatter()
    
    var minimumFractionDigits: Int = 0 {
        didSet {
            formatter.minimumFractionDigits = minimumFractionDigits
            updateFormat()
        }
    }
    
    var maximumFractionDigits: Int = 0 {
        didSet {
            formatter.maximumFractionDigits = maximumFractionDigits
            updateFormat()
        }
    }
    
    var spacing: CGFloat = 5.0 {
        didSet {
            stackView.spacing = spacing
        }
    }
    
    var buttonsSize: CGSize? {
        didSet {
            guard let buttonsSize = buttonsSize else {
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
    
    var buttonsTintColor: UIColor = .black {
        didSet {
            plusButton.tintColor = buttonsTintColor
            minusButton.tintColor = buttonsTintColor
        }
    }
    
    var accelerationModifier = 1
    
    var isEditing: Bool = false
    
    func message(for error: ErrorKey) -> String {
        switch error {
            case .crossedMax:
                return "Amount must be equal or less than \(limits.max!)"
            case .crossedMin:
                return "Amount must be equal or higher than \(limits.min!)"
            case .nonMultiple:
                return "Amount must be multiple of \(step)"
            case .incorrectSymbols:
                return "Incorrect symbols"
            default:
                break
        }
    }
    
    
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
        
        textField.delegate = self
        textField.borderStyle = .none
        textField.textAlignment = .center
        
        setTruncateHead()
        
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
        
//        formatter.localizesFormat = false
        formatter.locale = Locale(identifier: "en_US")
//        formatter.locale = .none
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        formatter.decimalSeparator = "."
    }
    
    func setupLayout() {
        stackView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(stackView)
        stackView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        stackView.leftAnchor.constraint(equalTo: self.leftAnchor).isActive = true
        stackView.rightAnchor.constraint(equalTo: self.rightAnchor).isActive = true
        stackView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true

        stackView.alignment = .center
        stackView.addArrangedSubview(minusButton)
        stackView.addArrangedSubview(textField)
        stackView.addArrangedSubview(plusButton)
        minusButton.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        plusButton.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        textField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    }
    
    override var intrinsicContentSize: CGSize {
        return stackView.intrinsicContentSize
    }

    func accelerate() {
        if accelerationModifier < 10 {
            accelerationModifier += 1
        }
    }
    
    func stepPlus() {
        textField.resignFirstResponder()
        endEditing()
        value += step * Double(accelerationModifier)
        updateState()
    }
    
    func stepMinus() {
        textField.resignFirstResponder()
        endEditing()
        value -= step * Double(accelerationModifier)
        updateState()
    }
    
    func abortTicking() {
        plusButton.cancelTouch()
        minusButton.cancelTouch()
        accelerationModifier = 1
        isEditing = false
    }
    
    func string(from value: Double) -> String? {
        return formatter.string(from: NSNumber(value: value))
    }
    
    func updateFormat() {
        guard let string = string(from: value) else {return}
        textField.text = string
        value = Double(string.removingComas()) ?? limits.min ?? 0
    }
    
    func updateButtons() {
        plusButton.isEnabled = validator.canStepUp(value: value)
        minusButton.isEnabled = validator.canStepDown(value: value)
    }
    
    func correctValue(_ value: Double, error: ErrorKey) -> Double {
        var correctValue: Double = limits.min ?? 0
        switch error {
            case .crossedMax:
                correctValue = limits.max!
                abortTicking()
            case .crossedMin:
                correctValue = limits.min!
                abortTicking()
            case .nonMultiple:
                correctValue = value - value.remainder(dividingBy: step)
            case .incorrectSymbols:
                correctValue = limits.min ?? 0
            default: break
        }
        return correctValue
    }
    
    func updateText() {
        guard let text = textField.text?.removingComas() else {return}
        let result = validator.checkText(text)
        if result.valid {
            if text == "" {
                textField.text = "0"
            } else {
                textField.text = text
            }
        } else {
            let error = result.errorKey!
            value = correctValue(value, error: error)
        }
        delegate?.stepperView(self, hasUpdatedWith: result)
        updateFormat()
    }
    
    func updateState() {
        updateButtons()
        updateText()
        updateFormat()
    }
    
    func setTruncateHead() {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = .byTruncatingHead
        paragraphStyle.alignment = .center
        
        let attr = [NSAttributedString.Key.paragraphStyle: paragraphStyle,
                    NSAttributedString.Key.font: font,
                    NSAttributedString.Key.foregroundColor: textColor
        ]
        textField.defaultTextAttributes = attr
    }
    
    func endEditing() {
        isEditing = false
        setTruncateHead()
    }
    
    func startEditing() {
        isEditing = true
        textField.defaultTextAttributes = [:]
        textField.font = font
        textField.textAlignment = .center
        textField.textColor = textColor
    }
    
// MARK: - UITextFieldDelegate methods
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        startEditing()
        delegate?.stepperView(self, hasUpdatedWith: .ok)
        textField.text = textField.text?.removingComas()
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        endEditing()
        updateState()
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let text = textField.text else { return false }
        let result = validator.shouldReplace(text: text, range: range, with: string)
        if result.allow {
            delegate?.stepperView(self, hasUpdatedWith: .ok)
            return true
        } else if let error = result.errorKey {
            delegate?.stepperView(self, hasUpdatedWith: .error(error))
            return false
        }
        textField.text = (text as NSString).replacingCharacters(in: range, with: result.replacement ?? "")
        return false
    }
}

extension String {
    func removingComas() -> String {
        return filter{!",".contains($0)}
    }
}
