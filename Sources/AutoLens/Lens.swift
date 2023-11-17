infix operator *~: MultiplicationPrecedence
infix operator |>: AdditionPrecedence

/**
 `Lens` is a generic structure that uses two placeholder types: `Whole` and `Part`.

 - Parameter get: A function that takes a `Whole` object as input and returns a `Part` object.
 - Parameter set: A function that takes a `Part` object and a `Whole` object as input and returns an new `Whole` object.

 Example:
 ```swift
 let personNameLens = Lens<Person, String>(
 get: { person in person.name },
 set: { (newName, person) in Person(name: newName, age: person.age) }
 )
 let person = Person(name: "John", age: 30)
 let johnsName = personNameLens.get(person) // "John"
 let olderJohn = personNameLens.set("Old John", person) // Person(name: "Old John", age: 30)
 ```
 */
public struct Lens<Whole, Part> {
    /// A function that takes a `Whole` object as input and returns a `Part` object.
    public let get: (Whole) -> Part
    /// A function that takes a `Part` object and a `Whole` object as input and returns an new `Whole` object.
    public let set: (Part, Whole) -> Whole

    public init(get: @escaping (Whole) -> Part, set: @escaping (Part, Whole) -> Whole) {
        self.get = get
        self.set = set
    }
}

public extension Lens {
    /**
     Transforms the `Lens` to a new `Lens` with different `Whole` and `Part` types.

     - Parameters:
       - transformPart: A function that transforms the `Part` type to a `TransformedPart` type.
       - reverseTransformPart: A function that reverses the transformation of `TransformedPart` type back to `Part`.
       - transformWhole: A function that transforms the `Whole` type to a `TransformedWhole` type.
       - reverseTransformWhole: A function that reverses the transformation of `TransformedWhole` type back to `Whole`.

     - Returns: A new `Lens` instance with the transformed `Whole` and `Part` types.

     Example:
     ```swift
     let personAgeLens = Lens<Person, Int>(
         get: { person in person.age },
         set: { (newAge, person) in Person(name: person.name, age: newAge) }
     )
     let personStringAgeLens = personAgeLens.map(
         transformPart: { age in String(age) },
         reverseTransformPart: { stringAge in Int(stringAge) ?? 0 },
         transformWhole: { person in person },
         reverseTransformWhole: { person in person }
     )
     let person = Person(name: "John", age: 30)
     let ageAsString = personStringAgeLens.get(person) // "30"
     let updatedPerson = personStringAgeLens.set("35", person) // Person(name: "John", age: 35)
     ```

     The `map` function allows the transformation of a `Lens` to operate on different types of `Whole` and `Part`. This is useful when you want to adapt a `Lens` to work with types that are derived or related to the original types.
     */
    func map<TransformedPart, TransformedWhole>(
        transformPart: @escaping (Part) -> TransformedPart,
        reverseTransformPart: @escaping (TransformedPart) -> Part,
        transformWhole: @escaping (Whole) -> TransformedWhole,
        reverseTransformWhole: @escaping (TransformedWhole) -> Whole
    ) -> Lens<TransformedWhole, TransformedPart> {
        .init { transformedWhole in
            transformPart(get(reverseTransformWhole(transformedWhole)))
        } set: { transformedPart, transformedWhole in
            transformWhole(set(reverseTransformPart(transformedPart), reverseTransformWhole(transformedWhole)))
        }
    }
}

public extension Lens {
    /**
     Creates an optional setter function for the `Lens`. It allows setting a `Part` on an optional `Whole`.
     If the `Whole` is `nil`, the function returns `nil`, otherwise, it applies the `set` operation.

     - Returns: A function that takes a `Part` and an optional `Whole`, and returns an optional `Whole`.

     Example:
     ```swift
     let personNameLens = Lens<Person, String>(
         get: { person in person.name },
         set: { (newName, person) in Person(name: newName, age: person.age) }
     )
     let person: Person? = Person(name: "John", age: 30)
     let updatedPerson = personNameLens.setMaybe("Jane", person) // Person(name: "Jane", age: 30)
     let nilPerson: Person? = nil
     let result = personNameLens.setMaybe("Jane", nilPerson) // nil
     ```

     The `setMaybe` function is particularly useful when dealing with optional `Whole` objects, providing a safe way to attempt setting a new `Part` without unwrapping the optional.
     */
    var setMaybe: (Part, Whole?) -> Whole? {
        { part, whole in
            guard let whole else { return nil }
            return set(part, whole)
        }
    }

    func setMaybe(_ part: Part) -> (Whole?) -> Whole? {
        { whole in
            guard let whole else { return nil }
            return set(part, whole)
        }
    }

    /**
     Creates an optional setter function for the `Lens`, which takes a function to derive the `Part` from the `Whole`.
     It allows setting a `Part` derived from an optional `Whole`. If the `Whole` is `nil`, the function returns `nil`,
     otherwise, it applies the `set` operation.

     - Returns: A function that takes a function to derive `Part` from `Whole`, and an optional `Whole`, and returns an optional `Whole`.

     Example:
     ```swift
     let personNameLens = Lens<Person, String>(
         get: { person in person.name },
         set: { (newName, person) in Person(name: newName, age: person.age) }
     )
     let person: Person? = Person(name: "John", age: 30)
     let updatedPerson = personNameLens.setMaybeWithWhole({ $0.name.uppercased() }, person) // Person(name: "JOHN", age: 30)
     let nilPerson: Person? = nil
     let result = personNameLens.setMaybeWithWhole({ $0.name.uppercased() }, nilPerson) // nil
     ```

     The `setMaybeWithWhole` function enables setting a `Part` that is derived from the `Whole`, with safety checks for optional `Whole`.
     */
    var setMaybeWithWhole: ((Whole) -> Part, Whole?) -> Whole? {
        { derivePartFromWhole, whole in
            guard let whole else { return nil }
            return set(derivePartFromWhole(whole), whole)
        }
    }
}

/**
  Combines two lenses into a single lens. This operator allows you to navigate through nested structures.

  - Parameters:
    - lhs: A `Lens` object focusing from a larger structure (`Whole`) to a smaller part (`Part`).
    - rhs: A `Lens` object focusing from the `Part` of the `lhs` lens to a further nested part.

  - Returns: A `Lens` object that combines the focus of both lenses.

  Example:
  ```swift
  let addressLens = Lens<Person, Address>(
      get: { $0.address },
      set: { (newAddress, person) in Person(name: person.name, address: newAddress) }
  )
  let cityLens = Lens<Address, String>(
      get: { $0.city },
      set: { (newCity, address) in Address(city: newCity) }
  )
  let personCityLens = addressLens * cityLens
  let person = Person(name: "John", address: Address(city: "New York"))
  let city = personCityLens.get(person) // "New York"
 ```
 */
public func * <A, B, C>(lhs: Lens<A, B>, rhs: Lens<B, C>) -> Lens<A, C> {
    Lens<A, C>(
        get: { a in rhs.get(lhs.get(a)) },
        set: { c, a in lhs.set(rhs.set(c, lhs.get(a)), a) }
    )
}

/**
 Creates a function that sets a specific value on a `Whole` using a `Lens`.

 - Parameters:
   - lhs: A `Lens` object focusing from a larger structure (`Whole`) to a smaller part (`Part`).
   - rhs: A value to set on the `Part` of the `lhs` lens.

 - Returns: A function that takes a `Whole` object and returns a new `Whole` object with the `rhs` value set on the `Part` of the `lhs` lens.

 Example:
 ```swift
 let nameLens = Lens<Person, String>(
     get: { $0.name },
     set: { (newName, person) in Person(name: newName, address: person.address) }
 )
 let person = Person(name: "John", address: Address(city: "New York"))
 let setNameToJane = nameLens *~ "Jane"
 let newPerson = setNameToJane(person) // Person(name: "Jane", address: Address(city: "New York"))
 ```

 The `*~` operator allows you to create a setter function for a `Lens` that sets a specific value on the `Part` of the `Lens`.
 */
public func *~ <A, B>(lhs: Lens<A, B>, rhs: B) -> (A) -> A {
    { a in lhs.set(rhs, a) }
}

/**
  Function application operator. Applies a function to an argument. This operator is useful for chaining function calls in a clear and concise way.

  - Parameters:
    - x: The input to the function.
    - f: The function to apply.

  - Returns: The result of applying the function to the input.

  Example:
  ```swift
  let nameLens = Lens<Person, String>(
      get: { $0.name },
      set: { (newName, person) in Person(name: newName, address: person.address) }
  )
  let person = Person(name: "John", address: Address(city: "New York"))
  let setNameToJane = nameLens *~ "Jane"
  let newPerson = person |> setNameToJane // Person(name: "Jane", address: Address(city: "New York")
 ```
 */
public func |> <A, B>(x: A, f: (A) -> B) -> B {
    f(x)
}

/**
  Composes two functions, creating a new function that applies the first function and then the second.

  - Parameters:
    - f: The first function to apply.
    - g: The second function to apply to the result of the first function.

  - Returns: A new function that represents the composition of `f` and `g`.

  Example:
  ```swift
  func increment(_ x: Int) -> Int { x + 1 }
  func square(_ x: Int) -> Int { x * x }

  let incrementAndSquare = increment |> square
  let result = incrementAndSquare(2) // (2 + 1) squared = 9
 ```
 */
public func |> <A, B, C>(f: @escaping (A) -> B, g: @escaping (B) -> C) -> (A) -> C {
    { g(f($0)) }
}
