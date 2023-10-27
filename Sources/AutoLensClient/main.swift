import AutoLens

@AutoLens
struct LensExample {
    static var v1 = 0
    var v2: Any { 0 }
    private let v3: Any
    public let v4: Any
    var v5: Int
    private(set) var v6: Any
}
