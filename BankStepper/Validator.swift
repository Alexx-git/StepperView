//
//  Validator.swift
//  BankStepper
//
//  Created by Vlad on 08.09.2020.
//  Copyright © 2020 Alexx. All rights reserved.
//

import Foundation

typealias Limits = (min: Currency?, max: Currency?)


extension Currency {
    func checkMax(limit: Currency?) -> Bool {
        return (limit != nil) ? self <= limit! : true
    }
    
    func checkMin(limit: Currency?) -> Bool {
        return (limit != nil) ? self >= limit! : true
    }
    
    func checkLimits(limits: Limits) -> Validator.Result {
        guard checkMax(limit: limits.max) else {return .error(.crossedMax)}
        guard checkMin(limit: limits.min) else {return .error(.crossedMin)}
        return .ok
    }
    
    func checkMultiple(step: Currency) -> Validator.Result {
        if self.truncatingRemainder(dividingBy: step) == 0 {
            return .ok
        } else {
            return .error(.nonMultiple)
        }
    }
}

struct Validator {
    
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
        static func noRepError(_ errorKey: ErrorKey?) -> Self {
            return Decision(allow: false, errorKey: errorKey, replacement: nil)
        }
    }
    
    
    struct Check: PStepperValidator {
        
        
        
        var limits: Limits = (nil, nil)
        
        var step: Currency
        
        init(limits: Limits = (nil, nil), step: Currency) {
            self.limits = limits
            self.step = step
        }
        
        func canStepUp(value: Currency) -> Bool {
            return (value + step).checkMax(limit: limits.max)
        }
        
        func canStepDown(value: Currency) -> Bool {
            return (value - step).checkMin(limit: limits.min)
        }
        
        func checkText(_ text: String?) -> Result {
            guard let value = Currency(text ?? "") else {return .error(ErrorKey.incorrectSymbols)}
            let result = value.checkLimits(limits: limits)
            guard result.valid else {return result}
            if value.checkMultiple(step: step).valid {
                return .ok
            } else {
                return .error(.nonMultiple)
            }
        }
        
        func shouldReplace(text: String? = "", range: NSRange, with string: String) -> Decision {
            let newText = (text! as NSString).replacingCharacters(in: range, with: string)
            guard (checkValueIsCorrect(text: newText) != nil) else { return .noRepError(.incorrectSymbols) }
            guard let value = Currency(newText) else { return .noRepError(.incorrectSymbols) }
            guard value.checkMax(limit: limits.max) else {return .noRepError(.crossedMax)}
            return Decision.ok
        }
        
        func checkValueIsCorrect(text: String, allowNegative: Bool = true, allowFloatingPoint: Bool = true) -> String? {
            var check = text
            if allowNegative && (check.first == "-") {
                check.remove(at: check.startIndex)
            }

            if allowFloatingPoint {
                guard let pointRange = check.range(of: ".") else {return nil}
                check.remove(at: pointRange.lowerBound)
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
        
        func removeBeginningZeros(text: inout String) {
            while text.first == "0" && text[text.startIndex] != "." {
                text.remove(at: text.startIndex)
            }
        }
    }

}
