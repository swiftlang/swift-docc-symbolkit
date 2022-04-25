/*
 This source file is part of the Swift.org open source project

 Copyright (c) 2022 Apple Inc. and the Swift project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
 See https://swift.org/CONTRIBUTORS.txt for Swift project authors
*/

import Foundation
import ArgumentParser
import SymbolKit

@main
struct DumpUnifiedGraph: ParsableCommand {
    @Option(help: ArgumentHelp("module's symbol graph to output", discussion: "will infer a single module, but will fail if multiple modules are being loaded"))
    var moduleName: String?

    @Flag(inversion: .prefixedNo,
          help: "whether to pretty-print the output JSON (default: true)")
    var prettyPrint: Bool = true

    @Option(name: .shortAndLong, help: "output file to write to (default: standard out)")
    var output: String?

    @Option(help: "directory to recursively load symbol graphs from", completion: .directory)
    var symbolGraphDir: String?

    @Argument(help: "list of symbol graphs to load", completion: .file(extensions: ["json"]))
    var files: [String] = []

    mutating func validate() throws {
        guard !files.isEmpty || symbolGraphDir != nil else {
            throw ValidationError("Please provide files or a symbol graph directory")
        }

        if let symbolGraphDir = symbolGraphDir, !symbolGraphDir.hasSuffix("/") {
            self.symbolGraphDir = symbolGraphDir.appending("/")
        }
    }

    func run() throws {
        var symbolGraphs = files
        if let symbolGraphDir = symbolGraphDir {
            symbolGraphs.append(contentsOf: loadSymbolGraphsFromDir(symbolGraphDir))
        }

        if symbolGraphs.isEmpty {
            print("error: No symbol graphs were available")
            throw ExitCode.failure
        }

        let decoder = JSONDecoder()
        let collector = GraphCollector()

        for symbolGraph in symbolGraphs {
            let graphUrl = URL(fileURLWithPath: symbolGraph)
            let decodedGraph = try decoder.decode(SymbolGraph.self, from: Data(contentsOf: graphUrl))
            collector.mergeSymbolGraph(decodedGraph, at: graphUrl)
        }

        let (unifiedGraphs, _) = collector.finishLoading()
        let outputGraph: UnifiedSymbolGraph

        if let moduleName = moduleName {
            if let graph = unifiedGraphs[moduleName] {
                outputGraph = graph
            } else {
                print("error: The given module was not represented in the symbol graphs")
                throw ExitCode.failure
            }
        } else {
            if unifiedGraphs.count > 1 {
                print("error: No module was given, but more than one module was represented in the symbol graphs")
                throw ExitCode.failure
            } else {
                outputGraph = unifiedGraphs.values.first!
            }
        }

        let encoder = JSONEncoder()
        if prettyPrint {
            encoder.outputFormatting.insert(.prettyPrinted)
        }

        let encoded = try encoder.encode(outputGraph)

        if let output = output, output != "-" {
            FileManager.default.createFile(atPath: output, contents: encoded)
        } else {
            let outString = String(data: encoded, encoding: .utf8)
            print(outString!)
        }
    }
}

func loadSymbolGraphsFromDir(_ dir: String) -> [String] {
    let enumerator = FileManager.default.enumerator(atPath: dir)
    var symbolGraphs: [String] = []

    while let filename = enumerator?.nextObject() as? String {
        if filename.hasSuffix(".symbols.json") {
            symbolGraphs.append(dir.appending(filename))
        }
    }

    return symbolGraphs
}
