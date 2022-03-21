# SymbolKit 

The specification and reference model for the *Symbol Graph* File Format.

A *Symbol Graph* models a *module*, also known in various programming languages as a "framework", "library", or "package", as a [directed graph](https://en.wikipedia.org/wiki/Directed_graph). In this graph, the nodes are declarations, and the edges connecting nodes are relationships between declarations.

By modeling different kinds of relationships, SymbolKit can provide rich data to power documentation, answering interesting questions, such as:

- *Which types conform to this protocol?*
- *What is the class hierarchy rooted at this class?*
- *Which protocol provides a requirement called `count`?*
- *Which types customize this protocol requirement?*

In addition, graph representations of data also present opportunities for visualizations in documentation, illustrating the structure or hierarchy of a module.

Please see SymbolKit's [documentation site](https://apple.github.io/swift-docc-symbolkit/documentation/symbolkit/) for more detailed information about the library.

## Getting Started Using SymbolKit

In your `Package.swift` Swift Package Manager manifest, add the following dependency to your `dependencies` argument:

```swift
.package(url: "https://github.com/apple/swift-docc-symbolkit.git", .branch("main")),
```

Add the dependency to any targets you've declared in your manifest:

```swift
.target(name: "MyTarget", dependencies: ["SymbolKit"]),
```

<!-- Copyright (c) 2021-2022 Apple Inc and the Swift Project authors. All Rights Reserved. -->
