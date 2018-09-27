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

public class SVG {

    class Error: NSError {

        static var invalidSVG: Swift.Error {
            return Error(code: 10, description: "Invalid URL")
        }

        static var invalidURL: Swift.Error {
            return Error(code: 20, description: "Could not get data from  URL")
        }

        init(code: Int, description: String) {
            super.init(
                domain: "SwiftSVG", code: code,
                userInfo: [NSLocalizedDescriptionKey: description])
        }

        required init?(coder aDecoder: NSCoder) { super.init(coder: aDecoder) }
    }

    public static func data(from SVGNamed: String) -> Data?  {
        if #available(iOS 9.0, OSX 10.11, *) {

            #if os(iOS)
            if let asset = NSDataAsset(name: SVGNamed) {
                return asset.data
            }
            #elseif os(OSX)
            if let asset = NSDataAsset(name: NSDataAsset.Name(SVGNamed)) {
                return asset.data
            }
            #endif

            if let svgURL = Bundle.main.url(forResource: SVGNamed, withExtension: "svg") {
                return try? Data(contentsOf: svgURL)
            }

        } else if let svgURL = Bundle.main.url(forResource: SVGNamed, withExtension: "svg") {
            return try? Data(contentsOf: svgURL)
        }

        return nil
    }


    public static func layer(from data: Data, parser: SVGParser? = nil,
                             success: @escaping (SVGLayer) -> (),
                             failure: ((Swift.Error) -> ())? = nil,
                             completion: (() -> ())? = nil) {

        if let cached = SVGCache.default[data.cacheKey]?.svgLayerCopy {
            success(cached)
            completion?()
            return
        }

        let dispatchQueue = DispatchQueue(label: "com.straussmade.swiftsvg", attributes: .concurrent)
        dispatchQueue.async {
            let parser = parser ?? NSXMLSVGParser(
                SVGData: data,
                success: { (svgLayer) in
                    DispatchQueue.global(qos: .userInitiated).async {
                        if let layerCopy = svgLayer.svgLayerCopy {
                            SVGCache.default[data.cacheKey] = layerCopy
                        }

                        dispatchQueue.async { success(svgLayer) }
                    }},
                failure: failure,
                completion: completion)

            parser.startParsing()
        }
    }
}
