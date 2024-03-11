/*
 This source file is part of the Swift.org open source project

 Copyright (c) 2024 Apple Inc. and the Swift project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
 See https://swift.org/CONTRIBUTORS.txt for Swift project authors
*/

import Foundation

fileprivate extension SymbolGraph.Symbol.DeclarationFragments.Fragment {
    init(textFragment text: String) {
        self.spelling = text
        self.kind = .text
        self.preciseIdentifier = nil
    }
}

fileprivate extension UnifiedSymbolGraph.Symbol {
    func declarationFragments(selector: UnifiedSymbolGraph.Selector) -> [SymbolGraph.Symbol.DeclarationFragments.Fragment]? {
        return (self.mixins[selector]?[SymbolGraph.Symbol.DeclarationFragments.mixinKey] as? SymbolGraph.Symbol.DeclarationFragments)?.declarationFragments
    }

    func functionSignature(selector: UnifiedSymbolGraph.Selector) -> SymbolGraph.Symbol.FunctionSignature? {
        return self.mixins[selector]?[SymbolGraph.Symbol.FunctionSignature.mixinKey] as? SymbolGraph.Symbol.FunctionSignature
    }
}

internal extension SymbolGraph.Symbol {
    func overloadSubheadingFragments() -> [DeclarationFragments.Fragment]? {
        guard let sourceFragments = self.declarationFragments ?? self.names.subHeading ?? self.names.navigator, !sourceFragments.isEmpty else {
            return nil
        }

        var simplifiedFragments = [DeclarationFragments.Fragment]()

        // In Swift, methods have a keyword as their first token; if the declaration follows that
        // pattern then pull that out
        if let firstFragment = sourceFragments.first, firstFragment.kind == .keyword {
            simplifiedFragments.append(firstFragment)
        }

        // Then, look for the first identifier, which should contain the symbol's name, and add that
        if let firstIdentifier = sourceFragments.first(where: { $0.kind == .identifier }) {
            if !simplifiedFragments.isEmpty {
                simplifiedFragments.append(.init(textFragment: " "))
            }
            simplifiedFragments.append(firstIdentifier)
        }

        // Assumption: All symbols that can be considered "overloads" are written with method
        // syntax, including a list of arguments surrounded by parentheses. In Swift symbol graphs,
        // method parameters are included in the FunctionSignature mixin, so if that's present we
        // use that to parse the data out.

        simplifiedFragments.append(.init(textFragment: "("))

        if let functionSignature = self.functionSignature {
            for parameter in functionSignature.parameters {
                // Scan through the declaration fragments to see whether this parameter's name is
                // externally-facing or not.
                let fragment: SymbolGraph.Symbol.DeclarationFragments.Fragment
                let parameterName = parameter.externalName ?? parameter.name
                if let paramNameFragment = sourceFragments.first(where: { $0.spelling == parameterName && $0.kind == .externalParameter }) {
                    fragment = paramNameFragment
                } else {
                    // If not, then insert an underscore for this parameter.
                    // FIXME: This is a Swift-centric assumption; change this if/when we support C++ overloads
                    fragment = .init(kind: .externalParameter, spelling: "_", preciseIdentifier: nil)
                }
                simplifiedFragments.append(fragment)
                simplifiedFragments.append(.init(textFragment: ":"))
            }
        } else {
            let parameterFragments = sourceFragments.extractFunctionParameters()
            simplifiedFragments.append(contentsOf: parameterFragments)
        }

        if simplifiedFragments.last?.kind == .text, var lastFragment = simplifiedFragments.popLast() {
            lastFragment.spelling += ")"
            simplifiedFragments.append(lastFragment)
        } else {
            simplifiedFragments.append(.init(textFragment: ")"))
        }

        return simplifiedFragments
    }
}

internal extension [SymbolGraph.Symbol.DeclarationFragments.Fragment] {
    func extractFunctionParameters() -> [SymbolGraph.Symbol.DeclarationFragments.Fragment] {
        var parameterFragments = [SymbolGraph.Symbol.DeclarationFragments.Fragment]()

        // A parameter can be named one of three ways:
        // 1. Only an external name
        // 2. External name followed by internal
        // 3. Only an internal name (can happen in Swift when subscripts have anonymous parameters)

        // To further complicate matters, function types in Swift are rendered with their parameter
        // names as proper internal/external parameter fragments. While we could try to scan through
        // for arguments flanked by parentheses, we should instead rely on the symbol graph to have
        // included the FunctionSignature mixin so that this method isn't called. This function will
        // fail to distinguish the parameter names and simply render them all inline.

        // If there are no parameter fragments in this declaration, assume no parameters and bail
        guard var currentIndex = self.firstIndex(where: \.isParameter) else {
            return []
        }
        // Assumption: Method/function declarations end their parameters list with a close
        // parenthesis, or (in Swift) an arrow. If we find neither of these, scan until the end of
        // the list.
        let endOfArguments = self.lastIndex(where: { $0.spelling.contains("->") })
            ?? self.lastIndex(where: { $0.spelling.contains(")") })
            ?? self.endIndex

        while currentIndex < endOfArguments {
            let currentFragment = self[currentIndex]
            if currentFragment.isParameter {
                if currentFragment.kind == .externalParameter {
                    parameterFragments.append(currentFragment)

                    // In Swift, parameters with distinct internal and external names are
                    // rendered with the external name first, followed by a space, then the
                    // internal name. If the next two fragments match that pattern, skip forward
                    // so we don't accidentally insert an extra underscore parameter.
                    if currentIndex + 2 < endOfArguments,
                       self[currentIndex + 1].spelling == " ",
                       self[currentIndex + 2].kind == .internalParameter 
                    {
                        currentIndex += 2
                    }
                } else {
                    // FIXME: This is a Swift-centric assumption; change this if/when we support C++ overloads
                    parameterFragments.append(.init(kind: .externalParameter, spelling: "_", preciseIdentifier: nil))
                }
                parameterFragments.append(.init(textFragment: ":"))
            }

            currentIndex += 1
        }

        return parameterFragments
    }
}

fileprivate extension SymbolGraph.Symbol.DeclarationFragments.Fragment {
    var isParameter: Bool {
        return self.kind == .internalParameter || self.kind == .externalParameter
    }
}
