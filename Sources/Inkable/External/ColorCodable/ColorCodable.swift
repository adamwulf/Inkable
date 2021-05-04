//
//  ColorCodable.swift
//  Inkable
//
//  Created by Adam Wulf on 3/27/21.
//

import Foundation
import UIKit

public struct CodableColor {

    /// The color to be (en/de)coded
    let color: UIColor
}

extension CodableColor: Encodable {

    public func encode(to encoder: Encoder) throws {
        let nsCoder = NSKeyedArchiver(requiringSecureCoding: true)
        color.encode(with: nsCoder)
        var container = encoder.unkeyedContainer()
        try container.encode(nsCoder.encodedData)
    }
}

extension CodableColor: Decodable {

    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let decodedData = try container.decode(Data.self)
        let nsCoder = try NSKeyedUnarchiver(forReadingFrom: decodedData)

        // You can use this if you don't want to use OptionalTools:
        guard let color = UIColor(coder: nsCoder) else {
            struct UnexpectedlyFoundNilError: Error {}

            throw UnexpectedlyFoundNilError()
        }

        self.color = color
    }
}

public extension UIColor {
    func codable() -> CodableColor {
        return CodableColor(color: self)
    }
}
