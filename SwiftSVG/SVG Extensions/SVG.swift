//
//  SVG.swift
//  SwiftSVG
//
//  Copyright (c) Chris Conover 9/9/18.
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

internal class SVG {

    static func layer(from data: Data, parser: SVGParser? = nil,
                      completion: @escaping (SVGLayer) -> (),
                      failure: @escaping (Error) -> ()) {

        if let cached = SVGCache.default[data.cacheKey]?.svgLayerCopy {
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
