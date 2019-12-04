//
//  File.swift
//  
//
//  Created by Tommy Hinrichsen on 04/12/2019.
//

import Foundation

enum GateKeeperError: Swift.Error {
    case forbidden
    case tooManyRequests
}
