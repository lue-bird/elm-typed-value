# elm-typed-value

> Create type-safe aliases for primitive types

Fundamental concepts are similar to [Prior art](#Prior-Art):

A value is wrapped in a `type` with a phantom `tag`, so that a `Typed A Int ...` is not a `Typed B Int ...`.

There are 3 wrappers in this package 

- `ReadOnly`:
    - only its value can be read everywhere
    - creating new ones & updating is only possible inside the module
- `WriteOnly`:
    - can be updated everywhere
    - its value can never be read
- `ReadWrite`:
    - you can both access the value & create new ones

→ additional type-safety.

## examples

```elm
import Typed exposing
    (Typed, WriteOnly, ReadOnly, writeOnly)
```

### `ReadWrite`

Basically a `type alias` with a phantom tag:

```elm
type alias Length unit =
    ReadWrite unit Float

type Meters = Meters
type Millimeters = Millimeters

-- use a type annotation: this should only convert meters
metersToMillimeters : Length Meters -> Length Millimeters
metersToMillimeters =
    Typed.map ((*) 1000)
        >> Typed.is Millimeters

-- annotate to set the unit
heightEiffelTower : Length Meters
heightEiffelTower =
    Typed.new Meters 300
```

### `ReadOnly`

```elm
-- must be in a seperate module
module DivisibleBy2 exposing
    ( DivisibleBy2, multiply, add
    , zero, two
    )

type alias DivisibleBy2 =
    ReadOnly DivisibleBy2Tag Int

-- don't expose this
type DivisibleBy2Tag =
    DivisibleBy2

multiply : Int -> DivisibleBy2 -> DivisibleBy2
multiply int =
    Typed.map ((*) int)
        >> Typed.is DivisibleBy2

add : DivisibleBy2 -> DivisibleBy2 -> DivisibleBy2
add toAdd =
    Typed.map2 (+) toAdd
        >> Typed.is DivisibleBy2

zero : DivisibleBy2
zero =
    Typed.new DivisibleBy2 0

two : DivisibleBy2
two =
    Typed.new DivisibleBy2 2
```

Then outside this module

```elm
iWantANumberDivisibleBy2 : DivisibleBy2 -> Cake

iWantANumberDivisibleBy2
    (Typed.new 3 {-tag not available-})

iWantANumberDivisibleBy2
    (DivisibleBy2.two
        |> DivisibleBy2.multiply -5
    )
--> Cake
```
Another example:

A module that only exposes randomly generated unique `Id`s:
```elm
module Id exposing (Id, random)

import Random

type IdTag = Id

type alias Id =
    ReadOnly IdTag String

random : Random.Generator Id
random =
    Random.map (Typed.new Id)
        ({-...-})
```
No `Id` can be created outside this package!

### `WriteOnly`

You should only need this rarely.

```elm
type alias Password =
    WriteOnly PasswordTag String

type PasswordTag = Password

type alias User =
    { name : String
    , password : Password
    }

update msg model =
    case msg of
        ChangePassword password ->
            { model
              | user =
                  { name = model.user.name
                  , password =
                      Typed.new Password password --valid
                  }
            }

leak (Typed.value model.user.password)
```
→ You can't get the value inside `password`. This is a compile-time error.

However, there's one thing you can still do
```elm
commonPasswords =
    Set.fromList
        [ "password", "secret", "p4ssw0rd", "1234" ]
        |> Set.map (Typed.new Password)

if Set.member model.user.password commonPasswords then
    "Choose a less common password. Use at lest 10 letters & symbols."
else
    "👍"
```

But if you wanted to find out if the length is >= 10 for example, just use `ReadOnly`.

## Prior art
This package wouldn't exist without a lot of inspiration from those packages.
- [Punie/elm-id](https://package.elm-lang.org/packages/Punie/elm-id/latest/)

especially
- [joneshf/elm-tagged](https://package.elm-lang.org/packages/joneshf/elm-tagged/latest/)
- [IzumiSy/elm-typed](https://package.elm-lang.org/packages/IzumiSy/elm-typed/latest/)
