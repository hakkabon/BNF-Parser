//
//  File.swift
//  BNF
//
//  Created by Ulf Akerstedt-Inoue on 2020/05/19.
//  Copyright © 2020 hakkabon software. All rights reserved.
//

import Foundation

public extension Parser {
    
    struct TraceOptions: OptionSet {
        public let rawValue: Int

        public static let bnf = TraceOptions(rawValue: 1 << 0)
        public static let bnftree = TraceOptions(rawValue: 1 << 1)
        public static let lex = TraceOptions(rawValue: 1 << 2)

        public static let all: TraceOptions = [.bnf,.lex]
        public static let pall: TraceOptions = [.bnftree,.lex]
        
        public init(rawValue: Int) {
            self.rawValue = rawValue
        }
    }
}
