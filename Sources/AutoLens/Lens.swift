infix operator *~: MultiplicationPrecedence
infix operator |>: AdditionPrecedence

public struct Lens<Whole, Part> {
    public let get: (Whole) -> Part
    public let set: (Part, Whole) -> Whole

    public init(get: @escaping (Whole) -> Part, set: @escaping (Part, Whole) -> Whole) {
        self.get = get
        self.set = set
    }
}

public extension Lens {
    func map<NewPart, NewWhole>(
        toNewPart: @escaping (Part) -> NewPart,
        toOldPart: @escaping (NewPart) -> Part,
        toNewWhole: @escaping (Whole) -> NewWhole,
        toOldWhole: @escaping (NewWhole) -> Whole
    ) -> Lens<NewWhole, NewPart> {
        .init { newWhole in
            toNewPart(get(toOldWhole(newWhole)))
        } set: { newPart, newWhole in
            toNewWhole(set(toOldPart(newPart), toOldWhole(newWhole)))
        }
    }
}

public extension Lens {
    var setMaybe: (Part, Whole?) -> Whole? {
        { part, whole in
            guard let whole else { return nil }
            return set(part, whole)
        }
    }

    var setMaybeWithWhole: ((Whole) -> Part, Whole?) -> Whole? {
        { part, whole in
            guard let whole else { return nil }
            return set(part(whole), whole)
        }
    }
}

public func * <A, B, C>(lhs: Lens<A, B>, rhs: Lens<B, C>) -> Lens<A, C> {
    Lens<A, C>(
        get: { a in rhs.get(lhs.get(a)) },
        set: { c, a in lhs.set(rhs.set(c, lhs.get(a)), a) }
    )
}

public func *~ <A, B>(lhs: Lens<A, B>, rhs: B) -> (A) -> A {
    { a in lhs.set(rhs, a) }
}

public func |> <A, B>(x: A, f: (A) -> B) -> B {
    f(x)
}

public func |> <A, B, C>(f: @escaping (A) -> B, g: @escaping (B) -> C) -> (A) -> C {
    { g(f($0)) }
}
