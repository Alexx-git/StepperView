//
//  Validator.swift
//  ValueStepper
//
//  Created by Alexx on 08.09.2020.
//  Copyright © 2020 Alexx. All rights reserved.
//

import Foundation

typealias Limits = (min: Double?, max: Double?)

extension Double {
    func checkMax(limit: Double?) -> Bool {
        return (limit != nil) ? self <= limit! : true
    }
    
    func checkMin(limit: Double?) -> Bool {
        return (limit != nil) ? self >= limit! : true
    }
    
    func checkLimits(limits: Limits) -> Result {
        guard checkMax(limit: limits.max) else { return .error(.crossedMax) }
        guard checkMin(limit: limits.min) else { return .error(.crossedMin) }
        return .ok
    }
    
    func checkMultiple(step: Double) -> Result {
        if self.truncatingRemainder(dividingBy: step) == 0 {
            return .ok
        } else {
            return .error(.nonMultiple)
        }
    }
    
    func fractionDigits() -> Int {
        var value = self
        var digits = 0
        while value.remainder(dividingBy: 1.0).magnitude > 0.00001 {
            digits += 1
            value *= 10.0
        }
        return digits
    }
}


class Validator: StepperViewValidator {
    
    
    private var limits: Limits = (nil, nil)
    
    private var step: Double
    
    init(limits: Limits = (nil, nil), step: Double) {
        self.limits = limits
        self.step = step
    }
    
    convenience init(with stepper: StepperView) {
        self.init(limits: stepper.limits, step: stepper.step)
    }
    
    func updateValues(from stepper: StepperView) {
        limits = stepper.limits
        step = stepper.step
    }
    
    func canStepUp(value: Double) -> Bool {
        return (value + step).checkMax(limit: limits.max)
    }
    
    func canStepDown(value: Double) -> Bool {
        return (value - step).checkMin(limit: limits.min)
    }
    
    func checkText(_ text: String?) -> Result {
        guard let value = Double(text ?? "0") else { return .error(ErrorKey.incorrectSymbols) }
        let result = value.checkLimits(limits: limits)
        guard result.valid else { return result }
        let stepValue = value - (limits.min ?? 0.0)
        if stepValue.checkMultiple(step: step).valid {
            return .ok
        } else {
            return .error(.nonMultiple)
        }
    }
    
    func shouldReplace(text: String? = "", range: NSRange, with string: String) -> Decision {
        let newText = (text! as NSString).replacingCharacters(in: range, with: string)
        guard (checkValueIsCorrect(text: newText) != nil) else { return .noReplacementError(.incorrectSymbols) }
        guard let value = Double(newText) else { return .noReplacementError(.incorrectSymbols) }
        guard value.checkMax(limit: limits.max) else { return .noReplacementError(.crossedMax) }
        return Decision.ok
    }
    
    func checkValueIsCorrect(text: String, allowNegative: Bool = true, allowFloatingPoint: Bool = true) -> String? {
        var check = text
        if allowNegative && (check.first == "-") {
            check.remove(at: check.startIndex)
        }

        if allowFloatingPoint {
            if let pointRange = check.range(of: ".") {
                check.remove(at: pointRange.lowerBound)
            }
        }
        if checkIfOnlyDigital(text: check) {
            return text
        } else {
            return nil
        }
        
    }
    
    func checkIfOnlyDigital(text: String) -> Bool {
        let charset = CharacterSet.decimalDigits
        return text.rangeOfCharacter(from: charset.inverted) == nil
    }
}
