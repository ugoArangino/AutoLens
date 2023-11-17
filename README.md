# Swift AutoLens Macro

A Swift Macro variant of [Sourcery AutoLenses](https://github.com/krzysztofzablocki/Sourcery/blob/master/Templates/Templates/AutoLenses.stencil)

As introduced by [Chris Eidhof](https://m.objc.io/@chris) in his [blog post](https://chris.eidhof.nl/post/lenses-in-swift/), Lenses are a functional way to access and modify immutable data structures. 

## Why to use Lenses

Lenses are a great way to access and modify immutable data structures. They are composable, type-safe and easy to use.

Otherwise, you would have to write a lot of boilerplate code to access and modify nested immutable data structures.

### Given the following data structures

```swift
struct Person {
    let name: String
    let address: Address
}

struct Address {
    let city: City
}

struct City {
    let name: String
}

let springfield = City(name: "Springfield")
let alice = Person(name: "Alice", address: Address(city: springfield))
```

### Without Lenses

```swift
// Get the city name
let cityName = alice.address.city.name // "Springfield"

// Set the city name

let metropolis = City(name: "Metropolis")
let newAddress = Address(city: metropolis)
let newPerson = Person(name: alice.name, address: newAddress)
```

These `.get' and `.set' functions can be composed or used in other functions.

### With Lenses

```swift
let personCityNameLens = Person.addressLens * Address.cityLens * City.nameLens

// Get the city name
let cityName = alice |> personCityNameLens.get // "Springfield"

// Set the city name
let movedToMetropolis = alice |> personCityNameLens *~ "Metropolis"
```

## Example

### Macro expansion

```swift
@AutoLens
struct Person {
    let name: String
    let address: Address

//    static let nameLens = Lens<Person, String>(
//        get: {
//            $0.name
//        },
//        set: { name, orginal in
//            Person(name: name, address: orginal.address)
//        }
//    )
//
//    static let addressLens = Lens<Person, Address>(
//        get: {
//            $0.address
//        },
//        set: { address, orginal in
//            Person(name: orginal.name, address: address)
//        }
//    )
}

@AutoLens
struct Address {
    let city: City

//    static let cityLens = Lens<Address, City>(
//        get: {
//            $0.city
//        },
//        set: { city, _ in
//            Address(city: city)
//        }
//    )
}

@AutoLens
struct City {
    let name: String
    
//    static let nameLens = Lens<City, String>(
//        get: {
//            $0.name
//        },
//        set: { name, _ in
//            City(name: name)
//        }
//    )
}
```

### Usage of Lenses and (Lens) operators

```swift
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
```
