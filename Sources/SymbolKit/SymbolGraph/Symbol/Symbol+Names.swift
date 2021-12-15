/*
 This source file is part of the Swift.org open source project

 Copyright (c) 2021 Apple Inc. and the Swift project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
 See https://swift.org/CONTRIBUTORS.txt for Swift project authors
*/

import Foundation

extension SymbolGraph.Symbol {
    /**
     The names of a symbol, suitable for display in various contexts.
     */
    public struct Names: Codable, Equatable {
        /**
         A name suitable for use a title on a "page" of documentation.
         */
        public var title: String

        /**
         An abbreviated form of the symbol's declaration for displaying in navigators where there may be limited horizontal space.
         */
        public var navigator: [DeclarationFragments.Fragment]?

        /**
         An abbreviated form of the symbol's declaration for displaying in subheadings or lists.
         */
        public var subHeading: [DeclarationFragments.Fragment]?

        /**
         A name to use in documentation prose or inline link titles.

         > Note: If undefined, use the `title`.
         */
        public var prose: String?

        public init(title: String, navigator: [DeclarationFragments.Fragment]?, subHeading: [DeclarationFragments.Fragment]?, prose: String?) {
            self.title = title
            self.navigator = navigator
            self.subHeading = subHeading
            self.prose = prose
        }
    }
}
