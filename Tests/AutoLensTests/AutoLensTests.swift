import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

import AutoLensMacros

let testMacros: [String: Macro.Type] = [
    "AutoLens": AutoLens.self,
]

final class AutoLensTests: XCTestCase {
    func testMacro() throws {
        assertMacroExpansion(
            """
            @AutoLens
            struct LensExample {
                static var v1 = 0
                var v2: Any { 0 }
                private let v3: Any
                public let v4: Any
                var v5: Int
                private(set) var v6: Any
            }
            """,
            expandedSource: """
            struct LensExample {
                static var v1 = 0
                var v2: Any { 0 }
                private let v3: Any
                public let v4: Any
                var v5: Int
                private(set) var v6: Any

                private static let v3Lens = Lens<LensExample, Any>(
                    get: {
                        $0.v3
                    },
                    set: { v3, orginal in
                        LensExample(v3: v3, v4: orginal.v4, v5: orginal.v5, v6: orginal.v6)
                    }
                    )

                public static let v4Lens = Lens<LensExample, Any>(
                    get: {
                        $0.v4
                    },
                    set: { v4, orginal in
                        LensExample(v3: orginal.v3, v4: v4, v5: orginal.v5, v6: orginal.v6)
                    }
                    )

                internal static let v5Lens = Lens<LensExample, Int>(
                    get: {
                        $0.v5
                    },
                    set: { v5, orginal in
                        LensExample(v3: orginal.v3, v4: orginal.v4, v5: v5, v6: orginal.v6)
                    }
                    )

                private static let v6Lens = Lens<LensExample, Any>(
                    get: {
                        $0.v6
                    },
                    set: { v6, orginal in
                        LensExample(v3: orginal.v3, v4: orginal.v4, v5: orginal.v5, v6: v6)
                    }
                    )
            }
            """,
            macros: testMacros
        )
    }
}
