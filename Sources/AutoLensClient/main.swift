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

@AutoLens
struct Person {
    let name: String
    let address: Address
}

@AutoLens
struct Address {
    let city: City
}

@AutoLens
struct City {
    let name: String
}

// Example Data
let springfield = City(name: "Springfield")
let alice = Person(name: "Alice", address: Address(city: springfield))

// Use get
let name = Person.nameLens.get(alice) // "Alice"

// Use set
let bob = Person.nameLens.set("Bob", alice) // Person(name: "Bob", address: Address(city: "Springfield"))

// Combining Lenses
let personCityNameLens = Person.addressLens * Address.cityLens * City.nameLens

// Using the Lens
let cityName = personCityNameLens.get(alice) // "Springfield"

// Using the `*~` operator to create a function that sets a new city name
let setCityNameToMetropolis = City.nameLens *~ "Metropolis"

// Applying the function to a City object
let metropolis = alice.address.city |> setCityNameToMetropolis
let personCityLens = Person.addressLens * Address.cityLens
let newPerson = alice |> personCityLens *~ metropolis

// Checking the updated person's city name
let updatedCityName = personCityNameLens.get(newPerson) // "Metropolis"
