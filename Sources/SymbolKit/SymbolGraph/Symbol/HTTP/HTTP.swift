/*
 This source file is part of the Swift.org open source project

 Copyright (c) 2023 Apple Inc. and the Swift project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
 See https://swift.org/CONTRIBUTORS.txt for Swift project authors
*/

import Foundation

extension SymbolGraph.Symbol {
    /// The HTTP endpoint for a request.
    public var httpEndpoint: HTTP.Endpoint? {
        (mixins[HTTP.Endpoint.mixinKey] as? HTTP.Endpoint)
    }
    
    /// The source location of an HTTP parameter.
    public var httpParameterSource: String? {
        (mixins[HTTP.ParameterSource.mixinKey] as? HTTP.ParameterSource)?.value
    }
    
    /// The encoding media type for an HTTP payload.
    public var httpMediaType: String? {
        (mixins[HTTP.MediaType.mixinKey] as? HTTP.MediaType)?.value
    }
    
    /// Namespace to hold mixins specific to HTTP requests
    public enum HTTP {
        
        /// The HTTP endpoint for a request.
        /// 
        /// Defines the HTTP method, base URL, and path relative to the base URL.
        public struct Endpoint: Mixin {
            public static let mixinKey = "httpEndpoint"
            
            private var _method: String
            
            /// The HTTP method of the request.
            /// 
            /// Expected values include GET, PUT, POST, DELETE.
            /// The value is always uppercased.
            public var method: String {
                get {
                    return self._method
                }
                set {
                    self._method = newValue.uppercased()
                }
            }
            
            /// The base URL of the request.
            /// 
            /// This portion of the URL is usually shared across all endpoints provided by a server.
            /// It can be optionally swapped out of the request by the ``sandboxURL`` when accessing
            /// the endpoint within a test environment.
            public var baseURL: URL
            
            /// The alternate base URL of the request when used within a test environment.
            public var sandboxURL: URL?
            
            /// The relative path specific to the endpoint.
            /// 
            /// The string can encode the location of parameters in the path using `{parameterName}` syntax.
            /// The embedded parameter name must match an `httpParameter` symbol related to this endpoint's `httpRequest` symbol.
            public var path: String
            
            public init(method: String, baseURL: URL, sandboxURL: URL? = nil, path: String) {
                self._method = method.uppercased()
                self.baseURL = baseURL
                self.sandboxURL = sandboxURL
                self.path = path
            }
            
            enum CodingKeys: CodingKey {
                case method
                case baseURL
                case sandboxURL
                case path
            }
            
            public init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                _method = try container.decode(String.self, forKey: .method).uppercased()
                baseURL = try container.decode(URL.self, forKey: .baseURL)
                sandboxURL = try container.decodeIfPresent(URL.self, forKey: .sandboxURL)
                path = try container.decode(String.self, forKey: .path)
            }
            
            public func encode(to encoder: Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)
                try container.encode(method, forKey: .method)
                try container.encode(baseURL, forKey: .baseURL)
                try container.encodeIfPresent(sandboxURL, forKey: .sandboxURL)
                try container.encode(path, forKey: .path)
            }
        }
        
        /// The source location of an HTTP parameter.
        /// 
        /// Expected values are path, query, header, or cookie.
        public struct ParameterSource: SingleValueMixin {
            public static let mixinKey = "httpParameterSource"
            public typealias ValueType = String
            public var value: ValueType
            public init(_ value: ValueType) {
                self.value = value
            }
        }
        
        /// The encoding media type for an HTTP payload.
        /// 
        /// Common values are "application/json" and "application/x-www-form-urlencoded".
        public struct MediaType: SingleValueMixin {
            public static let mixinKey = "httpMediaType"
            public typealias ValueType = String
            public var value: ValueType
            public init(_ value: ValueType) {
                self.value = value
            }
        }
    }
}
