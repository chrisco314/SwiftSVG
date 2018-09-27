//
//  SVGScalingView.swift
//  SwiftSVG
//
//  Copyright (c) Chris Conover 9/7/18.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//


#if os(iOS) || os(tvOS)
import UIKit
#elseif os(OSX)
import AppKit
#endif



public class SVGRenderingView: UIView {

    public func render(_ data: Data, parser: SVGParser? = nil,
                       success: (() -> ())? = nil,
                       failure: ((Error) -> ())? = nil) {

        reset()
        SVG.layer(
            from: data,
            success: { [weak self] (svgLayer) in
                DispatchQueue.main.safeAsync { [weak self] in
                    self?.nonOptionalLayer.addSublayer(svgLayer)
                    success?()
                }},
            failure: failure)
    }

    public func reset() { svgLayer?.removeFromSuperlayer() }

    override public func layoutSublayers(of layer: CALayer) {

        if layer === self.layer {
            if let svgLayer = svgLayer {
//                svgLayer.resizeToFit(bounds)
            }
        }
    }

    var svgLayer: SVGLayer? {
        return nonOptionalLayer.sublayers?.first as? SVGLayer
    }
}


public class SVGCenteringView: SVGRenderingView {

    override public func layoutSublayers(of layer: CALayer) {
        super.layoutSublayers(of: layer)

        if layer === self.layer {
            if let svgLayer = svgLayer {
                svgLayer.centerToFit(bounds)
            }
        }
    }
}
