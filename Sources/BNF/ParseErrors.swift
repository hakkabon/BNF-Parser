//
//  ParseErrors.swift
//  BNF
//
//  Created by Ulf Akerstedt-Inoue on 2020/05/19.
//  Copyright © 2020 hakkabon software. All rights reserved.
//

import Foundation
import Tokenizer

public extension Parser {
    
    enum Error: Swift.Error {
        case missingFileName
        case failedToOpenFile
    }
    
    enum ParseError: Swift.Error {
        case expressionNotRecognized(Token, expected: String)
        case unexpectedToken(Token, expected: Token)
        case unexpectedEOF
    }
}
