//
//  Parser.swift
//  BNF
//
//  Created by Ulf Akerstedt-Inoue on 2019/01/08.
//  Copyright © 2020 hakkabon software. All rights reserved.
//

import Foundation
import Files
import Tokenizer

/**
    The BNF description (syntax description) of the grammar:

    Syntax      : { Grammar | Tokens | Productions } ;
    Grammar     : 'grammar' Identifier ';' ;
    Tokens      : 'tokens' '{' { Identifier ':' Literal } '}' ;
    Productions : 'productions' '{' { Production } '}' ;
    Production  : Identifier ':' Expression ';' ;
    Expression  : Term { "|" Term } ;
    Term        : Factor { Factor } ;
    Factor      : Identifier
                | Literal
                | "[" Expression "]"
                | "(" Expression ")"
                | "{" Expression "}"
                | "{:" CODE_STRING ":}" ;
    Identifier  : letter { letter | "_" | "-" | "ε" } ;
    Literal     : """" character { character } """"
                | "'" character { character } "'" ;

    The alphabet of the `Literal` is currently limited to ASCII characters.
    This grammar definition is very close to the BNF grammar definition given
    by Niklaus Wirth [1], which resembles the EBNF definition [2] very closely.
 
    Punctuation characters are: '|', "[", "]", "(", ")" "{:", ":}".
 
    References:
    [1] https://en.wikipedia.org/wiki/Wirth_syntax_notation
    [2] https://en.wikipedia.org/wiki/Extended_Backus%E2%80%93Naur_form
    
    A simple grammar definition may look something like the example below:
 
    ~~~
    grammar lr_dragon;
    tokens {
      id : "[a-zA-Z]+"
    }
    productions {
        E     : E '+' T | T ;
        T     : T '*' F | F ;
        F     : '(' E ')' | 'id' ;
    }
    ~~~
*/

/// The Grammar Parser examinines the list of tokens provided by the Lexer (tokenizer).
/// Only a lookahaed of ONE token is actually necessary. The parser is written in a
/// top-down fashion (LL parser).
public class Parser {

    var tokenizer: Tokenizer
    var counter: Counter = Counter()
    public var syntax = ASTNode(.root)
    
    let symbols = ["//", "/*", "*\\", ":", ",", "->", ".", "\"", ">", "{", "[",
                   "{:", "<", "(", "!", "*", "|", "+", "'", "}", "]", ":}", ")", ";"]
    let keywords = ["grammar", "tokens", "productions"]

    /// Parses a language grammar description referenced by given file name.
    /// - Parameter file: text file (ascii) containing the complete grammar description of the language.
    /// - Throws: if failed to open file.
    public init(grammar file: File, level: TraceOptions = []) throws {
        do {
            let input = try file.readAsString()
            tokenizer = Tokenizer(source: input, filterComments: true, symbols: Set(symbols), keywords: Set(keywords))
        } catch {
            throw Error.failedToOpenFile
        }

        do {
            try parse(node: syntax)
            if level.contains(.bnf) {
                traverse(visitor: { (node,indent) in
                    print( String(format: "%@(%@ %@)", indent, String(describing: type(of: node)), node.description) )
                })
            } else if level.contains(.bnftree) {
                printPretty()
            }
        } catch (let error) {
            print(error)
        }
    }
    
    /// Parses a language grammar description given multiline string.
    /// - Parameter source: String containing the complete grammar description of the language.
    public init(grammar source: String, level: TraceOptions = []) {
        tokenizer = Tokenizer(source: source, filterComments: true, symbols: Set(symbols), keywords: Set(keywords))
        do {
            try parse(node: syntax)
            if level.contains(.bnf) {
                traverse(visitor: { (node,indent) in
                    print( String(format: "%@(%@ %@)", indent, String(describing: type(of: node)), node.description) )
                })
            } else if level.contains(.bnftree) {
                printPretty()
            }
        } catch (let error) {
            print(error)
        }
    }
    
    /// Walk parse tree with given visitor. Traverse all nodes in depth-first fashion.
    /// - Parameter visitor: visitor object acting on each object in the tree.
    public func traverse(visitor: (ASTNode) -> ()) {
        syntax.traverse(node: syntax, visitor: visitor)
    }

    /// Walk parse tree with given visitor. Traverse all nodes in depth-first fashion.
    /// - Parameter visitor: visitor object acting on each object in the tree.
    public func traverse(visitor: (ASTNode,String) -> ()) {
        syntax.traverse(node: syntax, indentation: "", visitor: visitor)
    }

    public func printPretty() {
        syntax.printTree()
    }
    
    /// Parses grammar in top-down fashion.
    /// Each grammar section (Grammar, Tokens {...}, Productions {...}) at a time.
    /// ~~~
    /// Syntax : { Grammar | Tokens | Productions }
    /// ~~~
    private func parse(node langauage: ASTNode) throws {
        while let token = tokenizer.next() {
            switch token {
            case let .keyword(value):
                switch value {
                case "grammar":
                    let identifier = try parseGrammarSection()
                    syntax.addChild(ASTNode(.grammar(identifier)))
                case "tokens":
                    let regularExpressions = try parseTokenSection()
                    regularExpressions.forEach( { syntax.addChild($0) } )
                case "productions":
                    let productions = try parseProductionSection()
                    productions.forEach( { syntax.addChild($0) } )
                default:
                    throw ParseError.expressionNotRecognized(.keyword(value), expected: "{ Grammar | Tokens | Productions }")
                }
            case .comment(_): break
            case let .symbol(value):
                throw ParseError.expressionNotRecognized(.symbol(value), expected: "{ Grammar | Tokens | Productions }")
            case let .identifier(value):
                throw ParseError.expressionNotRecognized(.identifier(value), expected: "{ Grammar | Tokens | Productions }")
            case let .literal(value):
                throw ParseError.expressionNotRecognized(.literal(value), expected: "{ Grammar | Tokens | Productions }")
            case let .number(value):
                throw ParseError.expressionNotRecognized(.number(value), expected: "{ Grammar | Tokens | Productions }")
            case let .space(value):
                throw ParseError.expressionNotRecognized(.space(value), expected: "{ Grammar | Tokens | Productions }")
            case let .invalid(value):
                throw ParseError.expressionNotRecognized(.invalid(value), expected: "{ Grammar | Tokens | Productions }")
            }
        }
    }
    
    /// Parses the grammar keyword and name definition.
    /// ~~~
    /// Grammar : 'grammar' Identifier ';'
    /// ~~~
    private func parseGrammarSection() throws -> String {
        let token = tokenizer.next()
        switch token {
        case let .identifier(ident):
            if tokenizer.peek(ahead: 1) == .symbol(";") { tokenizer.consume() }
            return ident
        default:
            throw ParseError.expressionNotRecognized(token!, expected: "'Identifier' ';'")
        }
    }
    
    /// Parses terminal definitions for which regex definitions).
    /// ~~~
    /// Tokens : 'tokens' '{' { Identifier : Terminal } '}'
    /// ~~~
    /// Note that the `tokens` keyword has already been recognized at this stage.
    private func parseTokenSection() throws -> [ASTNode] {
        var rhs = [ASTNode]()
        if tokenizer.peek(ahead: 1) == .symbol("{") { tokenizer.consume() }
        while tokenizer.peek(ahead: 1) != .symbol("}") {
            if case let .identifier(identifier) = tokenizer.next() {
                if tokenizer.peek(ahead: 1) == .symbol(":") { tokenizer.consume() }
                if case let .literal(definition) = tokenizer.next() {
                    rhs.append(ASTNode(.token(identifier, definition)))
                }
            }
        }
        if tokenizer.peek(ahead: 1) == .symbol("}") { tokenizer.consume() }
        return rhs
    }

    /// Parses the definition of all Productions.
    /// ~~~
    /// Productions : 'productions' '{' { Production } '}'
    /// ~~~
    private func parseProductionSection() throws -> [ASTNode] {
        var productions = [ASTNode]()
        if tokenizer.peek(ahead: 1) == .symbol("{") { tokenizer.consume() }
        while tokenizer.peek(ahead: 1) != .symbol("}") {
            productions.append(try parseProduction())
        }
        if tokenizer.peek(ahead: 1) == .symbol("}") { tokenizer.consume() }
        return productions
    }

    /// Parses the definition of one Production.
    /// ~~~
    /// Production : Identifier ':' Expression ';'
    /// ~~~
    private func parseProduction() throws -> ASTNode {
        let token = tokenizer.next()
        switch token {
        case let .identifier(identifier):
            let production = ASTNode(.production(counter.increment()))
            production.addChild(ASTNode(.lhs(identifier)))
            if tokenizer.peek(ahead: 1) == .symbol(":") { tokenizer.consume() }
            try parseExpression(expression: production)
            if tokenizer.peek(ahead: 1) == .symbol(";") { tokenizer.consume() }
            return production
        default:
            throw ParseError.expressionNotRecognized(token!, expected: "Identifier ':' Expression ';'")
        }
    }
    
    /// Parses the definition of Expression.
    /// ~~~
    /// Expression : Term { "|" Term }
    /// ~~~
    private func parseExpression(expression node: ASTNode) throws {
        try parseTerm(term: node)
        while tokenizer.peek(ahead: 1) == .symbol("|") {
            tokenizer.consume()
            node.addChild(ASTNode(.punctuation("|")))
            try parseTerm(term: node)
        }
    }

    /// Parses the definition of Expression.
    /// ~~~
    /// Term : Factor { Factor }
    /// ~~~
    /// Note: Lookahead (peek at next token without consuming it) is necessary to determine parsing
    /// strategy for the next token.
    private func parseTerm(term node: ASTNode) throws {
        try parseFactor(factor: node)
        while let token = tokenizer.peek(ahead: 1) {
            switch token {
            case .identifier(_): try parseFactor(factor: node)
            case .literal(_): try parseFactor(factor: node)
            case .symbol("["): try parseFactor(factor: node)
            case .symbol("("): try parseFactor(factor: node)
            case .symbol("{"): try parseFactor(factor: node)
            default:
                return
            }
        }
    }

    /// Parses the definition of Factor.
    /// ~~~
    /// Factor : Identifier
    ///        | Literal
    ///        | "[" Expression "]"
    ///        | "(" Expression ")"
    ///        | "{" Expression "}"
    /// ~~~
    private func parseFactor(factor node: ASTNode) throws {
        let token = tokenizer.next()

        switch token {
        case let .identifier(string):
            node.addChild(ASTNode(.nonterminal(string)))

        case let .literal(string):
            node.addChild(ASTNode(.terminal(string)))

        case .symbol("["):
            node.addChild(ASTNode(.punctuation("[")))
            try parseExpression(expression: node)
            if tokenizer.peek(ahead: 1) == .symbol("]") { tokenizer.consume() }
            node.addChild(ASTNode(.punctuation("]")))

        case .symbol("("):
            node.addChild(ASTNode(.punctuation("(")))
            try parseExpression(expression: node)
            if tokenizer.peek(ahead: 1) == .symbol(")") { tokenizer.consume() }
            node.addChild(ASTNode(.punctuation(")")))

        case .symbol("{"):
            node.addChild(ASTNode(.punctuation("{")))
            try parseExpression(expression: node)
            if tokenizer.peek(ahead: 1) == .symbol("}") { tokenizer.consume() }
            node.addChild(ASTNode(.punctuation("}")))

        default:
            throw ParseError.expressionNotRecognized(token!, expected: "Identifier | Literal | [ Expression ] | ( Expression ) | { Expression }")
        }
    }
}
