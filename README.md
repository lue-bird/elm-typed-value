# elm-typed-value

> Create type-safe aliases for primitive types

Fundamental concepts are similar to [Prior art](#Prior-Art).

The type can control:

- `ReadOnly`:
    - only its value can be read everywhere
    - creating new ones & calling `map`, `andThen` is only possible inside the module
- `WriteOnly`:
    - `map`, `andThen` can be called outside the module
    -  its value can only be read everywhere
- `ReadWrite`:
    - you can both access the value & create new ones

→ additional type-safety.

## Examples

```elm
import Val exposing (Val, ReadWrite, ReadOnly, WriteOnly)
```

### ReadWrite

Basically a `type alias` with a phantom tag:

```elm
module Length exposing (Length, Meters, Millimeters, metersToMillimeters)

type alias Length unit =
    Val unit Float ReadWrite

type Meters = Meters Never
type Millimeters = Millimeters Never

-- this annotation is importatnt
metersToMillimeters : Length Meters -> Length Millimeters
metersToMillimeters meters =
    meters |> Val.map ((*) 1000)
```

Then anywhere:

```elm
-- annotate to set the unit
heightEiffelTower : Length Meters
heightEiffelTower =
    300 |> Val.tag
```

### ReadOnly

```elm
module DivisibleBy2 exposing
    (DivisibleBy2, multiply, add, zero, two)

type alias DivisibleBy2 =
    Val DivisibleBy2Tag Int ReadOnly

-- don't expose this
type DivisibleBy2Tag =
    DivisibleBy2

multiply : Int -> DivisibleBy2 -> DivisibleBy2
multiply int =
    Val.write DivisibleBy2
        |> Val.map ((*) int)

add : DivisibleBy2 -> DivisibleBy2 -> DivisibleBy2
add toAdd =
    Val.write DivisibleBy2
        >> Val.map2 (+) toAdd

zero : DivisibleBy2
zero =
    Val.readOnly DivisibleBy2 (Val.tag 0)

two : DivisibleBy2
two =
    Val.readOnly DivisibleBy2 (Val.tag 2)
```

Then outside this module

```elm
iWantANumberDivisibleBy2 : DivisibleBy2 -> Cake

iWantANumberDivisibleBy2 (Val.tag 3)
--> compile-time error

iWantANumberDivisibleBy2
    (DivisibleBy2.two
        |> DivisibleBy2.multiply -5
    )
--> Cake
```
Another example:

A module that generates random unique `Id`s:
```elm
module Id exposing (Id, random)

import Random
import Val exposing (Val, ReadOnly)

type IdTag =
    Id

type alias Id =
    Val IdTag String ReadOnly

random : Random.Generator Id
random =
    Random.map (Val.new >> Val.readOnly Id)
        ({-...-})
```
No `Id` can be created outside this package!

### WriteOnly

You should only need this rarely.

```elm
module Password exposing (Password)

type alias Password =
    Val PasswordTag String WriteOnly

type PasswordTag =
    Password Never
```

anywhere:

```elm
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
                      Val.new password --valid
                  }
            }

-- hahahah muhuhuhuhaahahahah
leak (Val.untag model.user.password)
```
You can't get the value inside `password`. This is a compile-time error.

However, there's one thing you can still do
```elm
commonPasswords =
    Set.fromList
        [ "password", "secret", "p4ssw0rd", "1234" ]
        |> Set.map Val.tag

if Set.member model.user.password commonPasswords then
    "Choose a less common password. Use at lest 10 letters & symbols."
else
    "👍"
```

If you for example wanted to find out if the length is above 10, just use `ReadOnly`.

## Prior art
This package wouldn't exist without them.
- [Punie/elm-id](https://package.elm-lang.org/packages/Punie/elm-id/latest/)
especially
- [joneshf/elm-tagged](https://package.elm-lang.org/packages/joneshf/elm-tagged/latest/)
- [IzumiSy/elm-typed](https://package.elm-lang.org/packages/IzumiSy/elm-typed/latest/)
