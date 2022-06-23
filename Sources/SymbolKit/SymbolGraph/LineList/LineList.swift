/*
 This source file is part of the Swift.org open source project

 Copyright (c) 2021-2022 Apple Inc. and the Swift project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
 See https://swift.org/CONTRIBUTORS.txt for Swift project authors
*/

import Foundation

extension SymbolGraph {
    /**
     A `LineList` is a logical grouping of text ranges in a document making up a block of textual content.

     A line list shouldn't contain any documentation comment markers or newlines.

     For example, for the following C++\-style documentation comment:

     ```c++
     /// First line
     /// Second line
     void foo() {}
     ```

     The line list would be represented by the following LineList:

     ```json
    {
      "lines": [
        {
          "text": "First line",
          "range": {
            "start": {
              "line": 0,
              "character": 4
            },
            "end": {
              "line": 0,
              "character": 14
            }
          }
        },
        {
          "text": "Second line",
          "range": {
            "start": {
              "line": 1,
              "character": 4
            },
            "end": {
              "line": 1,
              "character": 15
            }
          }
        }
      ]
    }
    ```

     The same breakdown should occur for block-style documentation comments, as in:

     ```c++
     /**
     * First line
     * Second line
     */
     void foo() {}
     ```

     or:

     ```c++
     /**
     First line
     Second line
     */
     void foo() {}
     ```

     It is the responsibility of the tool generating the symbol graph to measure and trim indentation appropriately to project a logical block of text. In all of the above cases, logically, the text is:

     ```
     First line
     Second line
     ```

     That is the text content that would be parsed as markup.

     Line lists were chosen as the representation of documentation markup because each language may have different syntactic forms for documentation comments. This form works for both sequences of single-line comments or multi-line comment blocks.
     */
    public struct LineList: Codable, Equatable {
        /// The lines making up this line list.
        public var lines: [Line]
        
        /// The URI of the source file where the documentation comment originated.
        public var uri: String?
        
        /// The file URL of the source file where the documentation comment originated.
        @available(macOS 10.11, *)
        public var url: URL? {
            guard let uri = uri else { return nil }
            // The URI string provided in the symbol graph file may be an invalid URL (rdar://69242070)
            //
            // Using `URL.init(dataRepresentation:relativeTo:)` here handles URI strings with unescaped
            // characters without trying to escape or otherwise process the URI string in SymbolKit.
            return URL(dataRepresentation: Data(uri.utf8), relativeTo: nil)
        }
        
        /// The name of the source module where the documentation comment originated.
        public var moduleName: String?
        
        enum CodingKeys: String, CodingKey {
            case lines
            case uri
            case moduleName = "module"
        }
        
        public init(_ lines: [Line], uri: String? = nil, moduleName: String? = nil) {
            self.lines = lines
            self.uri = uri
            self.moduleName = moduleName
        }

        /**
         Translate a position from its *local space* to this line list's *file space*.

         For example, take the following documentation comment from a source file:

         ```swift
            0123456789ABCDEFGHI
         68 /// This is
         69 /// a doc comment.
         70 func foo() {}
         ```

         This has the following lines and ranges:

         ```none
         68:4-68:B "This is"
         69:4-69:I "a doc comment"
         ```

         However, documentation comments are typically projected out into a single, contiguous text block, like so:

         ```none
           0123456789ABCDE
         0 This is
         1 a doc comment.
         ```

         If you need to refer to a position or selection in this text block back in the source file, you will need to translate it from this local space to the file's space.
         This API will perform that transformation, taking it back to file space.

         - note: A `LineList` may not have range information, which may occur if the tool generating a symbol graph did not have access to source files or source position information.

         - precondition: `position.line >= 0 && position.line < lines.count`
         - parameter position: A position in its local space to be translated to file space.
         - returns: The position translated to file space if this line list has range information from the file, otherwise `nil`.
         */
        public func translateToFileSpace(_ position: SourceRange.Position) -> SourceRange.Position? {
            let fileLine = lines[position.line]
            guard let fileRange = fileLine.range else {
                return nil
            }
            return .init(line: fileRange.start.line, character: position.character + fileRange.start.character)
        }

        /**
         Translate a range from its *local space* to this line list's *file space*.

         This method calls the overload ``translateToFileSpace(_:)-9dlzx`` on each bound of the `range`.

         - Note: A range in its local space may cross over documentation comment markers in file space. For example:

         A selection of "`is\na doc comment`" in

         ```none
                v
           0123456789ABCDE
         0 This is
         1 a doc comment.
            ^
         ```

         will be the selection `is\n/// a doc comment` in the original file, crossing over the doc comment markers.

         ```swift
                    v
           0123456789ABCDEFGHI
         0 /// This is
         1 /// a doc comment.
                ^
         ```
         */
        public func translateToFileSpace(_ range: SourceRange) -> SourceRange? {
            guard let start = translateToFileSpace(range.start),
                let end = translateToFileSpace(range.end) else {
                    return nil
            }
            return .init(start: start, end: end)
        }
    }
}

extension SymbolGraph.LineList {
    /**
     A line extracted from text.

     If a `Line` is a selection of a line in a documentation comment, it should not contain any comment markers, such as `//`, `///`, `/**`, `*/`, etc.

     A `Line`'s `content` should not include newline characters.
     */
    public struct Line: Codable, Equatable {
        /**
         The line's textual content, not including any documentation comment markers or newlines.

         This may be an empty string, which represents an empty line.
         */
        public var text: String

        /// The line's range in a document if available.
        public var range: SourceRange?

        public init(text: String, range: SourceRange?) {
            self.text = text
            self.range = range
        }
    }
}
