/*
 This source file is part of the Swift.org open source project

 Copyright (c) 2021 Apple Inc. and the Swift project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
 See https://swift.org/CONTRIBUTORS.txt for Swift project authors
*/

extension SymbolGraph {
    /// A ``Platform`` describes the deployment environment for a ``Module-swift.struct``.
    public struct Platform: Codable, Equatable {
        /**
         The name of the architecture that this module targets, such as `x86_64` or `arm64`. If the module doesn't have a specific architecture, this may be undefined.
         */
        public var architecture: String?

        /**
         The platform vendor from which this module came, such as `apple` or `linux`.
         If there is no specific platform vendor, this may be undefined.
         */
        public var vendor: String?

        /**
         The operating system intended as the run environment. If no operating system is required, this may be undefined.
         */
        public var operatingSystem: OperatingSystem?

        /**
         The running environment on the platform.

         For example, software originally meant for the iOS operating system
         can run on macOS via the "macCatalyst" system, in which the
         `operatingSystem` is `ios` and the `environment` is `macabi`.
         */
        public var environment: String?

        /**
         The name of the platform as it is generally known.

         For example, the *macCatalyst* platform corresponds to an
         operating system of *iOS* and a running environment of *macabi*.
         */
        public var name: String? {
            guard let os = operatingSystem?.name else {
                return nil
            }
            switch os {
            case "macosx", "macos":
                return SymbolGraph.Symbol.Availability.Domain.macOS
            case "ios":
                if environment == "macabi" {
                    return SymbolGraph.Symbol.Availability.Domain.macCatalyst

                } else {
                    return SymbolGraph.Symbol.Availability.Domain.iOS
                }
            case "watchos":
                return SymbolGraph.Symbol.Availability.Domain.watchOS
            case "tvos":
                return SymbolGraph.Symbol.Availability.Domain.tvOS
            case "linux":
                return SymbolGraph.Symbol.Availability.Domain.linux
            default:
                return "Unsupported OS: \(os)"
            }
        }

        public init(architecture: String? = nil, vendor: String? = nil, operatingSystem: OperatingSystem? = nil, environment: String? = nil) {
            self.architecture = architecture
            self.vendor = vendor
            self.operatingSystem = operatingSystem
            self.environment = environment
        }
    }
}
