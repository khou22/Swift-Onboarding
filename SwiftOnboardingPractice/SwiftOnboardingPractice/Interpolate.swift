//
//  Interpolate.swift
//  GestureDrivenAnimations
//
//  Created by Roy Marmelstein on 10/04/2016.
//  Copyright © 2016 Roy Marmelstein. All rights reserved.
//

import Foundation
import QuartzCore
import UIKit

/// Interpolate class. Responsible for conducting interpolations.
public class Interpolate {
    
    //MARK: Properties and variables
    
    /// Progress variable. Takes a value between 0.0 and 1,0. CGFloat. Setting it triggers the apply closure.
    public var progress: CGFloat = 0.0 {
        didSet {
            progress = max(0, min(progress, 1.0))
            let nextInternalProgress = self.adjustedProgress(progress)
            let easingProgress = nextInternalProgress - internalProgress
            internalProgress = nextInternalProgress
            let vectorCount = from.vectors.count
            for index in 0..<vectorCount {
                current.vectors[index] += diffVectors[index]*easingProgress
            }
            apply?(current.toInterpolatable())
        }
    }
    
    private var current: IPValue
    private let from: IPValue
    private let to: IPValue
    private var duration: CGFloat = 0.2
    private var diffVectors = [CGFloat]()
    private let function: InterpolationFunction
    private var internalProgress: CGFloat = 0.0
    private var targetProgress: CGFloat = 0.0
    private var apply: (Interpolatable -> ())?
    private var displayLink: CADisplayLink?
    
    //MARK: Lifecycle
    
    /**
     Initialises an Interpolate object.
     
     - parameter from:     Source interpolatable object.
     - parameter to:       Target interpolatable object.
     - parameter apply:    Apply closure.
     - parameter function: Interpolation function (Basic / Spring / Custom).
     
     - returns: an Interpolate object.
     */
    public init<T: Interpolatable>(from: T, to: T, function: InterpolationFunction = BasicInterpolation.Linear, apply: (T -> ())) {
        let fromVector = from.vectorize()
        let toVector = to.vectorize()
        self.current = fromVector
        self.from = fromVector
        self.to = toVector
        self.apply = { let _ = ($0 as? T).flatMap(apply) }
        self.function = function
        self.diffVectors = calculateDiff(fromVector, to: toVector)
    }
    
    /**
     Invalidates the apply function
     */
    public func invalidate() {
        apply = nil
    }
    
    //MARK: Animation
    
    /**
     Animates to a targetProgress with a given duration.
     
     - parameter targetProgress: Target progress value. Optional. If left empty assumes 1.0.
     - parameter duration:       Duration in seconds. CGFloat.
     */
    public func animate(targetProgress: CGFloat = 1.0, duration: CGFloat) {
        self.targetProgress = targetProgress
        self.duration = duration
        displayLink?.invalidate()
        displayLink = CADisplayLink(target: self, selector: #selector(next))
        displayLink?.addToRunLoop(NSRunLoop.mainRunLoop(), forMode: NSRunLoopCommonModes)
    }
    
    /**
     Stops animation.
     */
    public func stopAnimation() {
        displayLink?.invalidate()
    }
    
    //MARK: Internal
    
    /**
     Calculates diff between two IPValues.
     
     - parameter from: Source IPValue.
     - parameter to:   Target IPValue.
     
     - returns: Array of diffs. CGFloat
     */
    private func calculateDiff(from: IPValue, to: IPValue) -> [CGFloat] {
        var diffArray = [CGFloat]()
        let vectorCount = from.vectors.count
        for index in 0..<vectorCount {
            let vectorDiff = to.vectors[index] - from.vectors[index]
            diffArray.append(vectorDiff)
        }
        return diffArray
    }
    
    /**
     Adjusted progress using interpolation function.
     
     - parameter progressValue: Actual progress value. CGFloat.
     
     - returns: Adjusted progress value. CGFloat.
     */
    private func adjustedProgress(progressValue: CGFloat) -> CGFloat {
        return function.apply(progressValue)
    }
    
    /**
     Next function used by animation(). Increments progress based on the duration.
     */
    @objc private func next() {
        let direction: CGFloat = (targetProgress > progress) ? 1.0 : -1.0
        progress += 1/(self.duration*60)*direction
        if (direction > 0 && progress >= targetProgress) || (direction < 0 && progress <= targetProgress) {
            progress = targetProgress
            stopAnimation()
        }
    }
    
}

/**
 *  Interpolation function. Must implement an application function.
 */
public protocol InterpolationFunction {
    /**
     Applies interpolation function to a given progress value.
     
     - parameter progress: Actual progress value. CGFloat
     
     - returns: Adjusted progress value. CGFloat.
     */
    func apply(progress: CGFloat) -> CGFloat
}

/**
 Basic interpolation function.
 */
public enum BasicInterpolation: InterpolationFunction {
    /// Linear interpolation.
    case Linear
    /// Ease in interpolation.
    case EaseIn
    /// Ease out interpolation.
    case EaseOut
    /// Ease in out interpolation.
    case EaseInOut
    
    /**
     Apply interpolation function
     
     - parameter progress: Input progress value
     
     - returns: Adjusted progress value with interpolation function.
     */
    public func apply(progress: CGFloat) -> CGFloat {
        switch self {
        case .Linear:
            return progress
        case .EaseIn:
            return progress*progress*progress
        case .EaseOut:
            return (progress - 1)*(progress - 1)*(progress - 1) + 1.0
        case .EaseInOut:
            if progress < 0.5 {
                return 4.0*progress*progress*progress
            } else {
                let adjustment = (2*progress - 2)
                return 0.5 * adjustment * adjustment * adjustment + 1.0
            }
        }
    }
}

/// Spring interpolation
public class SpringInterpolation: InterpolationFunction {
    
    /// Damping
    public var damping: CGFloat = 10.0
    /// Mass
    public var mass: CGFloat = 1.0
    /// Stiffness
    public var stiffness: CGFloat = 100.0
    /// Velocity
    public var velocity: CGFloat = 0.0
    
    /**
     Initialise Spring interpolation
     
     - returns: a SpringInterpolation object
     */
    public init() {}
    
    /**
     Initialise Spring interpolation with options.
     
     - parameter damping:   Damping.
     - parameter velocity:  Velocity.
     - parameter mass:      Mass.
     - parameter stiffness: Stiffness.
     
     - returns: a SpringInterpolation object
     */
    public init(damping: CGFloat, velocity: CGFloat, mass: CGFloat, stiffness: CGFloat) {
        self.damping = damping
        self.velocity = velocity
        self.mass = mass
        self.stiffness = stiffness
    }
    
    /**
     Apply interpolation function
     
     - parameter progress: Input progress value
     
     - returns: Adjusted progress value with interpolation function.
     */
    public func apply(progress: CGFloat) -> CGFloat {
        
        if damping <= 0.0 || stiffness <= 0.0 || mass <= 0.0 {
            fatalError("Incorrect animation values")
        }
        
        let beta = damping / (2 * mass)
        let omega0 = sqrt(stiffness / mass)
        let omega1 = sqrt((omega0 * omega0) - (beta * beta))
        let omega2 = sqrt((beta * beta) - (omega0 * omega0))
        
        let x0: CGFloat = -1
        
        let oscillation: (CGFloat) -> CGFloat
        
        if beta < omega0 {
            // Underdamped
            oscillation = {t in
                let envelope: CGFloat = exp(-beta * t)
                
                let part2: CGFloat = x0 * cos(omega1 * t)
                let part3: CGFloat = ((beta * x0 + self.velocity) / omega1) * sin(omega1 * t)
                return -x0 + envelope * (part2 + part3)
            }
        } else if beta == omega0 {
            // Critically damped
            oscillation = {t in
                let envelope: CGFloat = exp(-beta * t)
                return -x0 + envelope * (x0 + (beta * x0 + self.velocity) * t)
            }
        } else {
            // Overdamped
            oscillation = {t in
                let envelope: CGFloat = exp(-beta * t)
                let part2: CGFloat = x0 * cosh(omega2 * t)
                let part3: CGFloat = ((beta * x0 + self.velocity) / omega2) * sinh(omega2 * t)
                return -x0 + envelope * (part2 + part3)
            }
        }
        
        return oscillation(progress)
    }
}

/**
 *  Interpolatable protocol. Requires implementation of a vectorize function.
 */
public protocol Interpolatable {
    /**
     Vectorizes the type and returns and IPValue
     */
    func vectorize() -> IPValue
}

/**
 Supported interpolatable types.
 */

public enum InterpolatableType {
    /// CATransform3D type.
    case CATransform3D
    /// CGAffineTransform type.
    case CGAffineTransform
    /// CGFloat type.
    case CGFloat
    /// CGPoint type.
    case CGPoint
    /// CGRect type.
    case CGRect
    /// CGSize type.
    case CGSize
    /// ColorHSB type.
    case ColorHSB
    /// ColorMonochrome type.
    case ColorMonochrome
    /// ColorRGB type.
    case ColorRGB
    /// Double type.
    case Double
    /// Int type.
    case Int
    /// NSNumber type.
    case NSNumber
    /// UIEdgeInsets type.
    case UIEdgeInsets
}

// MARK: Extensions

/// CATransform3D Interpolatable extension.
extension CATransform3D: Interpolatable {
    /**
     Vectorize CATransform3D.
     
     - returns: IPValue
     */
    public func vectorize() -> IPValue {
        return IPValue(type: .CATransform3D, vectors: [m11, m12, m13, m14, m21, m22, m23, m24, m31, m32, m33, m34, m41, m42, m43, m44])
    }
}

/// CGAffineTransform Interpolatable extension.
extension CGAffineTransform: Interpolatable {
    /**
     Vectorize CGAffineTransform.
     
     - returns: IPValue
     */
    public func vectorize() -> IPValue {
        return IPValue(type: .CGAffineTransform, vectors: [a, b, c, d, tx, ty])
    }
}

/// CGFloat Interpolatable extension.
extension CGFloat: Interpolatable {
    /**
     Vectorize CGFloat.
     
     - returns: IPValue
     */
    public func vectorize() -> IPValue {
        return IPValue(type: .CGFloat, vectors: [self])
    }
}

/// CGPoint Interpolatable extension.
extension CGPoint: Interpolatable {
    /**
     Vectorize CGPoint.
     
     - returns: IPValue
     */
    public func vectorize() -> IPValue {
        return IPValue(type: .CGPoint, vectors: [x, y])
    }
}

/// CGRect Interpolatable extension.
extension CGRect: Interpolatable {
    /**
     Vectorize CGRect.
     
     - returns: IPValue
     */
    public func vectorize() -> IPValue {
        return IPValue(type: .CGRect, vectors: [origin.x, origin.y, size.width, size.height])
    }
}

/// CGSize Interpolatable extension.
extension CGSize: Interpolatable {
    /**
     Vectorize CGSize.
     
     - returns: IPValue
     */
    public func vectorize() -> IPValue {
        return IPValue(type: .CGSize, vectors: [width, height])
    }
}

/// Double Interpolatable extension.
extension Double: Interpolatable {
    /**
     Vectorize Double.
     
     - returns: IPValue
     */
    public func vectorize() -> IPValue {
        return IPValue(type: .Double, vectors: [CGFloat(self)])
    }
}

/// Int Interpolatable extension.
extension Int: Interpolatable {
    /**
     Vectorize Int.
     
     - returns: IPValue
     */
    public func vectorize() -> IPValue {
        return IPValue(type: .Int, vectors: [CGFloat(self)])
    }
}

/// NSNumber Interpolatable extension.
extension NSNumber: Interpolatable {
    /**
     Vectorize NSNumber.
     
     - returns: IPValue
     */
    public func vectorize() -> IPValue {
        return IPValue(type: .NSNumber, vectors: [CGFloat(self)])
    }
}

/// UIColor Interpolatable extension.
extension UIColor: Interpolatable {
    /**
     Vectorize UIColor.
     
     - returns: IPValue
     */
    public func vectorize() -> IPValue {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        
        if getRed(&red, green: &green, blue: &blue, alpha: &alpha) {
            return IPValue(type: .ColorRGB, vectors: [red, green, blue, alpha])
        }
        
        var white: CGFloat = 0
        
        if getWhite(&white, alpha: &alpha) {
            return IPValue(type: .ColorMonochrome, vectors: [white, alpha])
        }
        
        var hue: CGFloat = 0, saturation: CGFloat = 0, brightness: CGFloat = 0
        
        getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        
        return IPValue(type: .ColorHSB, vectors: [hue, saturation, brightness, alpha])
    }
}

/// UIEdgeInsets Interpolatable extension.
extension UIEdgeInsets: Interpolatable {
    /**
     Vectorize UIEdgeInsets.
     
     - returns: IPValue
     */
    public func vectorize() -> IPValue {
        return IPValue(type: .UIEdgeInsets, vectors: [top, left, bottom, right])
    }
}

/// IPValue class. Contains a vectorized version of an Interpolatable type.
public class IPValue {
    
    let type: InterpolatableType
    var vectors: [CGFloat]
    
    init (type: InterpolatableType, vectors: [CGFloat]) {
        self.vectors = vectors
        self.type = type
    }
    
    func toInterpolatable() -> Interpolatable {
        switch type {
        case .CATransform3D:
            return CATransform3D(m11: vectors[0], m12: vectors[1], m13: vectors[2], m14: vectors[3], m21: vectors[4], m22: vectors[5], m23: vectors[6], m24: vectors[7], m31: vectors[8], m32: vectors[9], m33: vectors[10], m34: vectors[11], m41: vectors[12], m42: vectors[13], m43: vectors[14], m44: vectors[15])
        case .CGAffineTransform:
            return CGAffineTransform(a: vectors[0], b: vectors[1], c: vectors[2], d: vectors[3], tx: vectors[4], ty: vectors[5])
        case .CGFloat:
            return vectors[0]
        case .CGPoint:
            return CGPoint(x: vectors[0], y: vectors[1])
        case .CGRect:
            return CGRect(x: vectors[0], y: vectors[1], width: vectors[2], height: vectors[3])
        case .CGSize:
            return CGSize(width: vectors[0], height: vectors[1])
        case .ColorRGB:
            return UIColor(red: vectors[0], green: vectors[1], blue: vectors[2], alpha: vectors[3])
        case .ColorMonochrome:
            return UIColor(white: vectors[0], alpha: vectors[1])
        case .ColorHSB:
            return UIColor(hue: vectors[0], saturation: vectors[1], brightness: vectors[2], alpha: vectors[3])
        case .Double:
            return vectors[0]
        case .Int:
            return vectors[0]
        case .NSNumber:
            return vectors[0]
        case .UIEdgeInsets:
            return UIEdgeInsetsMake(vectors[0], vectors[1], vectors[2], vectors[3])
        }
    }
}


