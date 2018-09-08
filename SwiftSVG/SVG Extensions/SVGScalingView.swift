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

internal class Builder {

    static func svg(from data: Data, parser: SVGParser? = nil,
                    completion: @escaping (SVGLayer) -> (),
                    failure: @escaping (Error) -> ()) {

        if let cached = SVGCache.default[data.cacheKey] {
            completion(cached)
            return
        }

        let dispatchQueue = DispatchQueue(label: "com.straussmade.swiftsvg", attributes: .concurrent)
        dispatchQueue.async {
            let parser = parser ?? NSXMLSVGParser(
                SVGData: data,
                failure: failure,
                completion: { (svgLayer) in
                    DispatchQueue.global(qos: .userInitiated).async {
                        if let layerCopy = svgLayer.svgLayerCopy {
                            SVGCache.default[data.cacheKey] = layerCopy
                        }
                        dispatchQueue.async { completion(svgLayer) }
                    }
            })

            parser.startParsing()
        }
    }
}


public class SVGScalingView: UIView {

    public func render(_ data: Data, parser: SVGParser? = nil,
                completion: (() -> ())? = nil,
                failure: @escaping ((Error) -> ())) {

        reset()
        Builder.svg(
            from: data,
            completion: {
                [weak self] (svgLayer) in
                DispatchQueue.main.safeAsync { [weak self] in
                    self?.layer.addSublayer(svgLayer)
                }
                completion?()
            },
            failure: { failure($0) })
    }

    public func reset() { svgLayer?.removeFromSuperlayer() }

    override public func layoutSublayers(of layer: CALayer) {
        if layer === self.layer {
            print("SvgView.layoutSublayers: resizing svgLayer to main layer")
            if let _ = svgLayer {
                print("detected svg layer, updating...")
            }
            svgLayer?.resizeToFit(bounds)
        }
    }

    var svgLayer: SVGLayer? {
        return layer.sublayers?.first as? SVGLayer
    }
}
