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


## Contributing to Symbolkit

Contributions to /swift-docc-symbolkit are welcomed and encouraged! Please see the
[Contributing to Swift guide](https://swift.org/contributing/).

Before submitting the pull request, please make sure you have [tested your
 changes](https://github.com/apple/swift/blob/main/docs/ContinuousIntegration.md)
 and that they follow the Swift project [guidelines for contributing
 code](https://swift.org/contributing/#contributing-code).

To be a truly great community, [Swift.org](https://swift.org/) needs to welcome
developers from all walks of life, with different backgrounds, and with a wide
range of experience. A diverse and friendly community will have more great
ideas, more unique perspectives, and produce more great code. We will work
diligently to make the Swift community welcoming to everyone.

To give clarity of what is expected of our members, Swift has adopted the
code of conduct defined by the Contributor Covenant. This document is used
across many open source communities, and we think it articulates our values
well. For more, see the [Code of Conduct](https://swift.org/code-of-conduct/).

<!-- Copyright (c) 2021-2022 Apple Inc and the Swift Project authors. All Rights Reserved. -->
