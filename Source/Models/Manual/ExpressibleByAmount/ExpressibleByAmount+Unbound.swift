//
// MIT License
//
// Copyright (c) 2018-2019 Open Zesame (https://github.com/OpenZesame)
// 
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
// 
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
//

import Foundation

public extension Locale {
    var decimalSeparatorForSure: String {
        if let decimalSeparator = decimalSeparator {
            return decimalSeparator
        } else {
            let nsLocale = NSLocale(localeIdentifier: identifier)
            return nsLocale.decimalSeparator
        }
    }
}

public extension ExpressibleByAmount where Self: Unbound {
    /// Most important "convenience" init
    init(_ value: Magnitude) {
        self.init(qa: Self.toQa(magnitude: value))
    }
    
    init(valid: Magnitude) {
        self.init(valid)
    }
}

public extension ExpressibleByAmount where Self: Unbound {
    
    init(_ doubleValue: Double) {
        self.init(qa: Self.toQa(double: doubleValue))
    }
    
    init(_ intValue: Int) {
        self.init(Magnitude(intValue))
    }
    
    init(
        trimming untrimmed: String,
        trimmingString: (String) throws -> String = { try Self.trimmingAndFixingDecimalSeparator(in: $0) }
    ) throws {
        let trimmed = try trimmingString(untrimmed)
        
        if let mag = Magnitude(decimalString: trimmed) {
            self = Self.init(mag)
        } else if let double = Double(trimmed) {
            self.init(double)
        } else {
            throw AmountError<Self>.nonNumericString
        }
    }
    
    init(
        untrimmed: String,
        decimalSeparator getDecimalSeparator: @autoclosure () -> String = { Locale.current.decimalSeparatorForSure }()
    ) throws {
        let decimalSeparator = getDecimalSeparator()
        try self.init(trimming: untrimmed) {
            try Self.trimmingAndFixingDecimalSeparator(in: $0, decimalSeparator: decimalSeparator)
        }
    }
}

public extension ExpressibleByAmount where Self: Unbound {
    init<E>(_ other: E) where E: ExpressibleByAmount {
        self.init(qa: other.qa)
    }
    
    init(zil: Zil) {
        self.init(zil)
    }
    
    init(li: Li) {
        self.init(li)
    }
    
    init(qa: Qa) {
        self.init(qa)
    }
}

public extension ExpressibleByAmount where Self: Unbound {
    init(zil zilString: String) throws {
        self.init(zil: try Zil(trimming: zilString))
    }
    
    init(li liString: String) throws {
        self.init(li: try Li(trimming: liString))
    }
    
    init(qa qaString: String) throws {
        self.init(qa: try Qa(trimming: qaString))
    }
}

public extension ExpressibleByAmount {
    static func trimmingAndFixingDecimalSeparator(
        in untrimmed: String,
        decimalSeparator getDecimalSeparator: @autoclosure () -> String = { Locale.current.decimalSeparatorForSure }()
    ) throws -> String {
        let whiteSpacesRemoved = untrimmed.replacingOccurrences(of: " ", with: "")
        
        let decimalSeparator = getDecimalSeparator()

        let incorrectDecimalSeparatorReplacedIfNeeded = whiteSpacesRemoved.replacingIncorrectDecimalSeparatorIfNeeded(decimalSeparator: decimalSeparator)
        
        guard incorrectDecimalSeparatorReplacedIfNeeded.doesNotContainMoreThanOneDecimalSeparator(decimalSeparator: decimalSeparator) else {
              throw AmountError<Self>.moreThanOneDecimalSeparator
        }
        
        if incorrectDecimalSeparatorReplacedIfNeeded.hasSuffix(decimalSeparator) {
            throw AmountError<Self>.endsWithDecimalSeparator
        }

        if incorrectDecimalSeparatorReplacedIfNeeded.decimalPlaces(decimalSeparator: decimalSeparator) > (abs(Unit.qa.exponent) - abs(Self.unit.exponent)) {
            throw AmountError<Self>.tooManyDecimalPlaces
        }
        
        return incorrectDecimalSeparatorReplacedIfNeeded
    }
}

// MARK: - ExpressibleByFloatLiteral
public extension ExpressibleByAmount where Self: Unbound {
    init(floatLiteral double: Double) {
        self.init(double)
    }
}

// MARK: - ExpressibleByIntegerLiteral
public extension ExpressibleByAmount where Self: Unbound {
    init(integerLiteral int: Int) {
        self.init(int)
    }
}

// MARK: - ExpressibleByStringLiteral
public extension ExpressibleByAmount where Self: Unbound {
    init(stringLiteral string: String) {
        do {
            try self = Self(trimming: string)
        } catch {
            fatalError("The `String` value (`\(string)`) passed was invalid, error: \(error)")
        }
    }
}
