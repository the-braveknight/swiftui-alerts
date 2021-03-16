//
//  ArrayBuilder.swift
//  alert-app
//
//  Created by Zaid Rahhawi on 3/16/21.
//

import Foundation

@_functionBuilder
public struct ArrayBuilder {
    public static func buildBlock<T>(_ elements: T...) -> [T] {
        elements
    }
}
