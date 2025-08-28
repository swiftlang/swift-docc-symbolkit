/*
 This source file is part of the Swift.org open source project

 Copyright (c) 2022 Apple Inc. and the Swift project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
 See https://swift.org/CONTRIBUTORS.txt for Swift project authors
*/

struct CrossImportOverlaySymbolGraphs {
    // example content from the Swift compiler tests that validate
    // symbolgraph extraction from import-overlays:
    // `test/SymbolGraph/Module/CrossImport.swift`
    
    // `A.symbols.json`
    static func base() -> String {
        """
        {
          "metadata": {
            "formatVersion": {
              "major": 0,
              "minor": 6,
              "patch": 0
            },
            "generator": "Swift version 6.2-dev (LLVM 22c18a5d2eb92f4, Swift 694274204ba65e0)"
          },
          "module": {
            "name": "A",
            "platform": {
              "architecture": "arm64",
              "vendor": "apple",
              "operatingSystem": {
                "name": "macosx",
                "minimumVersion": {
                  "major": 13,
                  "minor": 0
                }
              }
            }
          },
          "symbols": [
            {
              "kind": {
                "identifier": "swift.struct",
                "displayName": "Structure"
              },
              "identifier": {
                "precise": "s:1AAAV",
                "interfaceLanguage": "swift"
              },
              "pathComponents": [
                "A"
              ],
              "names": {
                "title": "A",
                "navigator": [
                  {
                    "kind": "identifier",
                    "spelling": "A"
                  }
                ],
                "subHeading": [
                  {
                    "kind": "keyword",
                    "spelling": "struct"
                  },
                  {
                    "kind": "text",
                    "spelling": " "
                  },
                  {
                    "kind": "identifier",
                    "spelling": "A"
                  }
                ]
              },
              "declarationFragments": [
                {
                  "kind": "keyword",
                  "spelling": "struct"
                },
                {
                  "kind": "text",
                  "spelling": " "
                },
                {
                  "kind": "identifier",
                  "spelling": "A"
                }
              ],
              "accessLevel": "public"
            },
            {
              "kind": {
                "identifier": "swift.property",
                "displayName": "Instance Property"
              },
              "identifier": {
                "precise": "s:1AAAV1xSivp",
                "interfaceLanguage": "swift"
              },
              "pathComponents": [
                "A",
                "x"
              ],
              "names": {
                "title": "x",
                "subHeading": [
                  {
                    "kind": "keyword",
                    "spelling": "var"
                  },
                  {
                    "kind": "text",
                    "spelling": " "
                  },
                  {
                    "kind": "identifier",
                    "spelling": "x"
                  },
                  {
                    "kind": "text",
                    "spelling": ": "
                  },
                  {
                    "kind": "typeIdentifier",
                    "spelling": "Int",
                    "preciseIdentifier": "s:Si"
                  }
                ]
              },
              "declarationFragments": [
                {
                  "kind": "keyword",
                  "spelling": "var"
                },
                {
                  "kind": "text",
                  "spelling": " "
                },
                {
                  "kind": "identifier",
                  "spelling": "x"
                },
                {
                  "kind": "text",
                  "spelling": ": "
                },
                {
                  "kind": "typeIdentifier",
                  "spelling": "Int",
                  "preciseIdentifier": "s:Si"
                }
              ],
              "accessLevel": "public"
            },
            {
              "kind": {
                "identifier": "swift.init",
                "displayName": "Initializer"
              },
              "identifier": {
                "precise": "s:1AAAV1xABSi_tcfc",
                "interfaceLanguage": "swift"
              },
              "pathComponents": [
                "A",
                "init(x:)"
              ],
              "names": {
                "title": "init(x:)",
                "subHeading": [
                  {
                    "kind": "keyword",
                    "spelling": "init"
                  },
                  {
                    "kind": "text",
                    "spelling": "("
                  },
                  {
                    "kind": "externalParam",
                    "spelling": "x"
                  },
                  {
                    "kind": "text",
                    "spelling": ": "
                  },
                  {
                    "kind": "typeIdentifier",
                    "spelling": "Int",
                    "preciseIdentifier": "s:Si"
                  },
                  {
                    "kind": "text",
                    "spelling": ")"
                  }
                ]
              },
              "functionSignature": {
                "parameters": [
                  {
                    "name": "x",
                    "declarationFragments": [
                      {
                        "kind": "identifier",
                        "spelling": "x"
                      },
                      {
                        "kind": "text",
                        "spelling": ": "
                      },
                      {
                        "kind": "typeIdentifier",
                        "spelling": "Int",
                        "preciseIdentifier": "s:Si"
                      }
                    ]
                  }
                ]
              },
              "declarationFragments": [
                {
                  "kind": "keyword",
                  "spelling": "init"
                },
                {
                  "kind": "text",
                  "spelling": "("
                },
                {
                  "kind": "externalParam",
                  "spelling": "x"
                },
                {
                  "kind": "text",
                  "spelling": ": "
                },
                {
                  "kind": "typeIdentifier",
                  "spelling": "Int",
                  "preciseIdentifier": "s:Si"
                },
                {
                  "kind": "text",
                  "spelling": ")"
                }
              ],
              "accessLevel": "public"
            }
          ],
          "relationships": [
            {
              "kind": "memberOf",
              "source": "s:1AAAV1xSivp",
              "target": "s:1AAAV"
            },
            {
              "kind": "memberOf",
              "source": "s:1AAAV1xABSi_tcfc",
              "target": "s:1AAAV"
            }
          ]
        }
        """
    }
    
    // `_A_B@A.symbols.json`
    static func overlaidA() -> String {
        """
        {
          "metadata": {
            "formatVersion": {
              "major": 0,
              "minor": 6,
              "patch": 0
            },
            "generator": "Swift version 6.2-dev (LLVM 22c18a5d2eb92f4, Swift 694274204ba65e0)"
          },
          "module": {
            "name": "A",
            "bystanders": [
              "B"
            ],
            "platform": {
              "architecture": "arm64",
              "vendor": "apple",
              "operatingSystem": {
                "name": "macosx",
                "minimumVersion": {
                  "major": 13,
                  "minor": 0
                }
              }
            }
          },
          "symbols": [
            {
              "kind": {
                "identifier": "swift.extension",
                "displayName": "Extension"
              },
              "identifier": {
                "precise": "s:e:s:1AAAV4_A_BE12transmogrify1BAEVyF",
                "interfaceLanguage": "swift"
              },
              "pathComponents": [
                "A"
              ],
              "names": {
                "title": "A",
                "navigator": [
                  {
                    "kind": "identifier",
                    "spelling": "A"
                  }
                ],
                "subHeading": [
                  {
                    "kind": "keyword",
                    "spelling": "extension"
                  },
                  {
                    "kind": "text",
                    "spelling": " "
                  },
                  {
                    "kind": "typeIdentifier",
                    "spelling": "A",
                    "preciseIdentifier": "s:1AAAV"
                  }
                ]
              },
              "swiftExtension": {
                "extendedModule": "A",
                "typeKind": "swift.struct"
              },
              "declarationFragments": [
                {
                  "kind": "keyword",
                  "spelling": "extension"
                },
                {
                  "kind": "text",
                  "spelling": " "
                },
                {
                  "kind": "typeIdentifier",
                  "spelling": "A",
                  "preciseIdentifier": "s:1AAAV"
                }
              ],
              "accessLevel": "public"
            },
            {
              "kind": {
                "identifier": "swift.method",
                "displayName": "Instance Method"
              },
              "identifier": {
                "precise": "s:1AAAV4_A_BE12transmogrify1BAEVyF",
                "interfaceLanguage": "swift"
              },
              "pathComponents": [
                "A",
                "transmogrify()"
              ],
              "names": {
                "title": "transmogrify()",
                "subHeading": [
                  {
                    "kind": "keyword",
                    "spelling": "func"
                  },
                  {
                    "kind": "text",
                    "spelling": " "
                  },
                  {
                    "kind": "identifier",
                    "spelling": "transmogrify"
                  },
                  {
                    "kind": "text",
                    "spelling": "() -> "
                  },
                  {
                    "kind": "typeIdentifier",
                    "spelling": "B",
                    "preciseIdentifier": "s:1BAAV"
                  }
                ]
              },
              "functionSignature": {
                "returns": [
                  {
                    "kind": "typeIdentifier",
                    "spelling": "B",
                    "preciseIdentifier": "s:1BAAV"
                  }
                ]
              },
              "swiftExtension": {
                "extendedModule": "A",
                "typeKind": "swift.struct"
              },
              "declarationFragments": [
                {
                  "kind": "keyword",
                  "spelling": "func"
                },
                {
                  "kind": "text",
                  "spelling": " "
                },
                {
                  "kind": "identifier",
                  "spelling": "transmogrify"
                },
                {
                  "kind": "text",
                  "spelling": "() -> "
                },
                {
                  "kind": "typeIdentifier",
                  "spelling": "B",
                  "preciseIdentifier": "s:1BAAV"
                }
              ],
              "accessLevel": "public"
            },
            {
              "kind": {
                "identifier": "swift.struct",
                "displayName": "Structure"
              },
              "identifier": {
                "precise": "s:4_A_B11LocalStructV",
                "interfaceLanguage": "swift"
              },
              "pathComponents": [
                "LocalStruct"
              ],
              "names": {
                "title": "LocalStruct",
                "navigator": [
                  {
                    "kind": "identifier",
                    "spelling": "LocalStruct"
                  }
                ],
                "subHeading": [
                  {
                    "kind": "keyword",
                    "spelling": "struct"
                  },
                  {
                    "kind": "text",
                    "spelling": " "
                  },
                  {
                    "kind": "identifier",
                    "spelling": "LocalStruct"
                  }
                ]
              },
              "declarationFragments": [
                {
                  "kind": "keyword",
                  "spelling": "struct"
                },
                {
                  "kind": "text",
                  "spelling": " "
                },
                {
                  "kind": "identifier",
                  "spelling": "LocalStruct"
                }
              ],
              "accessLevel": "public"
            },
            {
              "kind": {
                "identifier": "swift.method",
                "displayName": "Instance Method"
              },
              "identifier": {
                "precise": "s:4_A_B11LocalStructV8someFuncyyF",
                "interfaceLanguage": "swift"
              },
              "pathComponents": [
                "LocalStruct",
                "someFunc()"
              ],
              "names": {
                "title": "someFunc()",
                "subHeading": [
                  {
                    "kind": "keyword",
                    "spelling": "func"
                  },
                  {
                    "kind": "text",
                    "spelling": " "
                  },
                  {
                    "kind": "identifier",
                    "spelling": "someFunc"
                  },
                  {
                    "kind": "text",
                    "spelling": "()"
                  }
                ]
              },
              "functionSignature": {
                "returns": [
                  {
                    "kind": "text",
                    "spelling": "()"
                  }
                ]
              },
              "swiftExtension": {
                "extendedModule": "_A_B",
                "typeKind": "swift.struct"
              },
              "declarationFragments": [
                {
                  "kind": "keyword",
                  "spelling": "func"
                },
                {
                  "kind": "text",
                  "spelling": " "
                },
                {
                  "kind": "identifier",
                  "spelling": "someFunc"
                },
                {
                  "kind": "text",
                  "spelling": "()"
                }
              ],
              "accessLevel": "public"
            }
          ],
          "relationships": [
            {
              "kind": "extensionTo",
              "source": "s:e:s:1AAAV4_A_BE12transmogrify1BAEVyF",
              "target": "s:1AAAV",
              "targetFallback": "A.A"
            },
            {
              "kind": "memberOf",
              "source": "s:1AAAV4_A_BE12transmogrify1BAEVyF",
              "target": "s:e:s:1AAAV4_A_BE12transmogrify1BAEVyF",
              "targetFallback": "A.A"
            },
            {
              "kind": "memberOf",
              "source": "s:4_A_B11LocalStructV8someFuncyyF",
              "target": "s:4_A_B11LocalStructV"
            }
          ]
        }
        """
    }

    // `_A_B@B.symbols.json`
    static func overlaidB() -> String {
        """
        {
          "metadata": {
            "formatVersion": {
              "major": 0,
              "minor": 6,
              "patch": 0
            },
            "generator": "Swift version 6.2-dev (LLVM 22c18a5d2eb92f4, Swift 694274204ba65e0)"
          },
          "module": {
            "name": "A",
            "bystanders": [
              "B"
            ],
            "platform": {
              "architecture": "arm64",
              "vendor": "apple",
              "operatingSystem": {
                "name": "macosx",
                "minimumVersion": {
                  "major": 13,
                  "minor": 0
                }
              }
            }
          },
          "symbols": [
            {
              "kind": {
                "identifier": "swift.extension",
                "displayName": "Extension"
              },
              "identifier": {
                "precise": "s:e:s:1BAAV4_A_BE14untransmogrify1AAEVyF",
                "interfaceLanguage": "swift"
              },
              "pathComponents": [
                "B"
              ],
              "names": {
                "title": "B",
                "navigator": [
                  {
                    "kind": "identifier",
                    "spelling": "B"
                  }
                ],
                "subHeading": [
                  {
                    "kind": "keyword",
                    "spelling": "extension"
                  },
                  {
                    "kind": "text",
                    "spelling": " "
                  },
                  {
                    "kind": "typeIdentifier",
                    "spelling": "B",
                    "preciseIdentifier": "s:1BAAV"
                  }
                ]
              },
              "swiftExtension": {
                "extendedModule": "B",
                "typeKind": "swift.struct"
              },
              "declarationFragments": [
                {
                  "kind": "keyword",
                  "spelling": "extension"
                },
                {
                  "kind": "text",
                  "spelling": " "
                },
                {
                  "kind": "typeIdentifier",
                  "spelling": "B",
                  "preciseIdentifier": "s:1BAAV"
                }
              ],
              "accessLevel": "public"
            },
            {
              "kind": {
                "identifier": "swift.method",
                "displayName": "Instance Method"
              },
              "identifier": {
                "precise": "s:1BAAV4_A_BE14untransmogrify1AAEVyF",
                "interfaceLanguage": "swift"
              },
              "pathComponents": [
                "B",
                "untransmogrify()"
              ],
              "names": {
                "title": "untransmogrify()",
                "subHeading": [
                  {
                    "kind": "keyword",
                    "spelling": "func"
                  },
                  {
                    "kind": "text",
                    "spelling": " "
                  },
                  {
                    "kind": "identifier",
                    "spelling": "untransmogrify"
                  },
                  {
                    "kind": "text",
                    "spelling": "() -> "
                  },
                  {
                    "kind": "typeIdentifier",
                    "spelling": "A",
                    "preciseIdentifier": "s:1AAAV"
                  }
                ]
              },
              "functionSignature": {
                "returns": [
                  {
                    "kind": "typeIdentifier",
                    "spelling": "A",
                    "preciseIdentifier": "s:1AAAV"
                  }
                ]
              },
              "swiftExtension": {
                "extendedModule": "B",
                "typeKind": "swift.struct"
              },
              "declarationFragments": [
                {
                  "kind": "keyword",
                  "spelling": "func"
                },
                {
                  "kind": "text",
                  "spelling": " "
                },
                {
                  "kind": "identifier",
                  "spelling": "untransmogrify"
                },
                {
                  "kind": "text",
                  "spelling": "() -> "
                },
                {
                  "kind": "typeIdentifier",
                  "spelling": "A",
                  "preciseIdentifier": "s:1AAAV"
                }
              ],
              "accessLevel": "public"
            }
          ],
          "relationships": [
            {
              "kind": "extensionTo",
              "source": "s:e:s:1BAAV4_A_BE14untransmogrify1AAEVyF",
              "target": "s:1BAAV",
              "targetFallback": "B.B"
            },
            {
              "kind": "memberOf",
              "source": "s:1BAAV4_A_BE14untransmogrify1AAEVyF",
              "target": "s:e:s:1BAAV4_A_BE14untransmogrify1AAEVyF",
              "targetFallback": "B.B"
            }
          ]
        }
        """
    }
}
