# elm-typed-value

> no more 1-constructor types

Fundamental concepts are similar to [Prior art](#Prior-Art):

A value is wrapped in the `type Typed` with a phantom `tag`.
So in the end, a `Typed Dollar Int ...` can't be called a `Typed Euro Int ...`.

For **every** `type` that has just 1 constructor with a value
```elm
type Special
    = Special Value
```
some `Typed` is better suited!

You get rid of always writing the same mehods for those types

```elm
extract (Special value) =
    value

map alter (Special value) =
    Special (alter value)

--...
```

while adding type-safety on your way.

There are 2 kinds of `Typed`:

  - `Checked`, if the type should only contain "validated" values

    ```elm
    module NaturalNumber exposing (NaturalNumber)

    -- nobody can create a NaturalNumber outside this module
    type NaturalNumber =
        NaturalNumber Int
    ```

    Creating & updating `NaturalNumber`s will only be possible inside that module.

  - `Tagged`, if you want to write

    ```elm
    -- constructor can be used anywhere
    type Meters =
        Meters Float
    ```

    Users can then access the `Float` `value`, update it & create new `Meters` everywhere


If you don't want users to access the `value` directly, use `CheckedHidden` / `TaggedHidden`.


# examples

```elm
import Typed exposing
    ( Tagged, Checked, CheckedHidden, TaggedHidden
    , tag, hideValue, hiddenValueIn, isChecked
    )
```

## `Tagged`

```elm
type alias Length unit =
    Tagged (LengthUnit unit) Float

type LengthUnit unit
    = LengthUnit Never

type Meters = Meters Never
type Millimeters = Millimeters Never

-- use a type annotation to say which units are translated
metersToMillimeters : Length Meters -> Length Millimeters
metersToMillimeters =
    Typed.map ((*) 1000)

-- annotate to set the unit
heightEiffelTower : Length Meters
heightEiffelTower =
    tag 300
```

## `Checked`

```elm
module Even exposing
    ( Even
    , multiply, add
    , zero, two
    )

type alias Even =
    Checked EvenTag Int

-- don't expose this
type EvenTag = Even

multiply : Int -> Even -> Even
multiply int =
    Typed.map ((*) int)
        >> isChecked Even

add : Even -> Even -> Even
add toAdd =
    Typed.map2 (+) toAdd
        >> isChecked Even

zero : Even
zero =
    tag 0 |> isChecked Even

two : Even
two =
    tag 2 |> isChecked Even
```

Then outside this module

```elm
iWantANumberEven : Even -> Cake

iWantANumberEven (tag 3)
--> compile-time error: isn't of type Checked

iWantANumberEven
    (Even.two |> Even.multiply -5)
--> Cake
```

## `CheckedHidden`

A validated value that can't be accessed by a user.

A module that only exposes randomly generated unique `Id`s:

```elm
module Id exposing (Id, random, toBytes, toString)

import Random

type alias Id =
    CheckedHidden IdTag CurrentImplementation

-- left as an implementation detail
-- might change in the future, but the API should stay the same
type alias CurrentImplementation =
    String

type IdTag = Id

random : Random.Generator Id
random =
    Random.map (isChecked Id)
        ({-...-})

toBytes --...
toString --...
```
No `Id` can be created outside this package!

### Combined with `TaggedHidden`

```elm
module Password exposing (Password, GoodPassword, isGood)

type alias Password =
    TaggedHidden PasswordTag String

type alias GoodPassword =
    CheckedHidden GoodPasswordTag String

-- don't expose any tag
type PasswordTag = Password Never
type GoodPasswordTag = GoodPassword

isGood :
    Password -> Result String GoodPassword
isGood passwordToTest =
    let
        passwordString =
            hiddenValueIn Password passwordToTest
    in
    if (passwordString |> String.length) < 10 then
        "Use at lest 10 letters & symbols."
    else if Set.member passwordString commonPasswords then
        "Choose a less common password."
    else
        Ok (passwordToTest |> isChecked GoodPassword)

commonPasswords =
    Set.fromList
        [ "password1234", "secret1234"
        , "c001_p4ssw0rd", "1234567890"
        --...
        ]
```
You can then decide that only a part of the information should be accessible.
```elm
{-| Doesn't expose too much information.
-}
toOnlyDots : Password -> List Char
toOnlyDots =
    hiddenValueIn Password
        >> String.length
        >> (\dots-> List.repeat dots '·')
```
In another module
```elm
type alias User =
    { name : String
    , password : GoodPassword
        --there can't be a user with a insecure password
    }

type Msg
    --cannot access the password the user changed to
    = ChangePassword Password

update msg model =
    case msg of
        ChangePassword newPassword ->
            { model
              | user =
                  { name = model.user.name
                  , password =
                      case Password.isGood newPassword of
                          Ok goodPasword ->
                              -- valid
                          Err message ->
                              -- tell the user
                  }
            }

view model =
    button [ onPress (tag >> ChangePassword) ]
        [ text "Change Password" ]
```
→ There can't be a `User` with a bad password.
```elm
leak (Typed.value newPassword)
-- or
leak (Typed.value model.user.password)
```
→ compile-time error: Can't get the `value` inside `password`.

## Prior art
This package wouldn't exist without a lot of inspiration from those packages.
- [Punie/elm-id](https://package.elm-lang.org/packages/Punie/elm-id/latest/)

especially
- [joneshf/elm-tagged](https://package.elm-lang.org/packages/joneshf/elm-tagged/latest/)
- [IzumiSy/elm-typed](https://package.elm-lang.org/packages/IzumiSy/elm-typed/latest/)
