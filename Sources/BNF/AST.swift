//
//  AST.swift
//  BNF
//
//  Created by Ulf Akerstedt-Inoue on 2019/01/08.
//  Copyright © 2020 hakkabon software. All rights reserved.
//

import Foundation

/// The `GrammarNode` stores the information parsed by the parser, which comprises
/// of the value or symbol and its positional type depending where it was found
/// during parsing (its position in the parse tree).
public enum GrammarNode {
    case grammar(String)                // name of grammar
    case token(String,String)           // (identifier,value)
    case production(Int)                // production(count)
    case lhs(String)                    // lhs of a production rule
    case terminal(String)               // terminal symbol
    case nonterminal(String)            // nonterminal symbol
    case semanticAction(String)         // semantic action (unparsed string)
    case punctuation(String)            // punctuation symbol
    case root

    public var description: String {
        switch self {
        case let .grammar(identifier): return "Grammar: \(identifier)"
        case let .production(n): return "Production[\(n)]"
        case let .lhs(identifier): return "lhs: \(identifier)"
        case let .terminal(symbol): return "Terminal: \(symbol)"
        case let .nonterminal(identifier): return "Nonterminal: \(identifier)"
        case let .token(identifier,value): return "Token: (\(identifier), \(value))"
        case let .semanticAction(string): return "Semantic Action: \(string)"
        case let .punctuation(symbol): return "Punctuation: \(symbol)"
        case .root: return "Root Node"
        }
    }
}

public class ASTNode {

    // List of subnodes.
    var children: [ASTNode] = [ASTNode]()

    // The type of this node.
    public private(set) var node: GrammarNode = .root

    /// Constructs and initializes one `BnfNode` object.
    /// - Parameter node: the type that the node represents depending on the
    ///   position in the parse tree.
    public init(_ node: GrammarNode) {
        self.node = node
    }
    
    /// Adds a node to the parse tree.
    /// - Parameter node: the node to be added to the parse tree
    public func addChild(_ node: ASTNode) {
        self.children.append(node)
    }
    
    /// Traverses parse tree with in depth-first fashion.
    /// Only the node is accessible by the visitor.
    /// - Parameters:
    ///   - root: the node first visited
    ///   - visitor: the node being vistited
    public func traverse(node root: ASTNode, visitor: (ASTNode) -> ()) {
        visitor(root) // visit root node first
        for child in root.children { child.traverse(node: child, visitor: visitor) }
    }

    /// Traverses parse tree with in depth-first fashion.
    /// The node and the level of indentation accessible by the visitor, which is useful for printing.
    /// - Parameters:
    ///   - root: the node first visited
    ///   - space: amount of indentation in front of first node, default is ""
    ///   - visitor: the node being vistited
    public func traverse(node root: ASTNode, indentation space: String = "", visitor: (ASTNode,String) -> ()) {
        let tab = "    "
        visitor(root, space) // visit root node first
        for child in root.children { child.traverse(node: child, indentation: space + tab, visitor: visitor) }
    }
}

extension ASTNode: CustomStringConvertible {
    public var description: String {
        return node.description
    }
}

// MARK: - Tree outline for pretty printing
// https://stackoverflow.com/questions/46371513/printing-a-tree-with-indents-swift
extension ASTNode {
    func treeLines(_ nodeIndent: String = "", _ childIndent: String = "") -> [String] {
        let root: [String] = [ nodeIndent + description ]
        let tree: [String] = children.enumerated().map{ ($0 < children.count-1, $1) }
                .flatMap{ $0 ? $1.treeLines("┣╸","┃ ") : $1.treeLines("┗╸","  ") }
                .map{ childIndent + $0 }
        return root + tree
    }
    
    public func printTree() {
        print(treeLines().joined(separator:"\n"))
    }
}
