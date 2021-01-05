import ArgumentParser
import Files
import Tokenizer
import BNF

struct EBNF: ParsableCommand {

    @Argument(help: "Input file name to lexer") var input: String
    @Flag(help: "Pretty printed BNF parse tree") var tree: Bool = false

    mutating func run() throws {
        var level: Parser.TraceOptions = [Parser.TraceOptions.bnf]
        if tree {
            level.remove(Parser.TraceOptions.bnf)
            level.insert(Parser.TraceOptions.bnftree)
        }
        let _ = try Parser(grammar: File(path: input), level: level)
    }
}

EBNF.main()
