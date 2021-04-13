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

    type NaturalNumber =
        -- nobody outside this module can call this constructor
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
import Typed
    exposing
        ( Typed, NoUser, Anyone
        , Tagged, Checked, CheckedHidden, TaggedHidden
        , tag, hiddenValueIn, isChecked
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

```elm
heightEiffelTower |> metersToMillimeters
    |> metersToMillimeters
```
→ compile-time exception
> Expected: `Length Millimeters -> Length Millimeters`

> Found: `Length Meters -> Length Millimeters`

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
cakeForEvenNumbers : Even -> Cake

cakeForEvenNumbers (tag 3)
--> compile-time error: isn't of type Checked

cakeForEvenNumbers
    (Even.two |> Even.multiply -5)
--> Cake
```

## `CheckedHidden`

A validated value that can't be directly accessed by a user.

A module that only exposes randomly generated unique `Id`s:

```elm
module Id exposing (Id, random, toBytes, toString)

import Random

type alias Id =
    CheckedHidden IdTag CurrentImplementation

-- left as an implementation detail
-- might change in the future
-- but the API should stay the same
type alias CurrentImplementation =
    String

type IdTag = Id

random : Random.Generator Id
random =
    Random.list 16 ({-...-})
        |> Random.map (isChecked Id)

toBytes --...
toString --...
```
No `Id` can be created outside this package!

## Combined with `TaggedHidden`

```elm
module Password exposing (UncheckedPassword, GoodPassword, isGood, toOnlyDots)

type alias Password goodOrUnchecked =
    Typed PasswordTag String { goodOrUnchecked | canAccess : NoUser }

-- don't expose the tag
type PasswordTag
    = Password

type alias GoodPassword =
    Password { createdBy : NoUser }
    -- which makes it a CheckedHidden

type alias UncheckedPassword =
    Password { createdBy : Anyone }
    -- which makes it a TaggedHidden


isGood :
    UncheckedPassword -> Result String GoodPassword
isGood passwordToTest =
    let
        passwordString =
            hiddenValueIn Password passwordToTest
    in
    if (passwordString |> String.length) < 10 then
        Err "Use at lest 10 letters & symbols."
    else if Set.member passwordString commonPasswords then
        Err "Choose a less common password."
    else
        Ok (passwordToTest |> isChecked Password)

commonPasswords =
    Set.fromList
        [ "password1234", "secret1234"
        , "c001_p4ssw0rd", "1234567890"
        --...
        ]
```
You can then decide that only a part of the information should be accessible.
```elm
-- doesn't expose too much information.
toOnlyDots : Password goodOrUnchecked -> String
toOnlyDots =
    hiddenValueIn Password
        >> String.length
        >> (\length ->
                List.repeat length '·'
                    |> String.fromList
           )
```
In another module
```elm
type alias User =
    { name : String
    , password : GoodPassword
        
type alias Model =
    { passwordTypedIntoRegister : UncheckedPassword
        --cannot access the password the user typed
    , loggedIn : LoggedIn
    }

type LoggedIn
    = LoggedIn { userPassword : GoodPassword }
        --there can't be a user with an insecure password
    | NotLoggedIn


type Msg
    = PasswordTypedIntoRegisterChanged UncheckedPassword
    | Register GoodPassword

update msg model =
    case msg of
        PasswordTypedIntoRegisterChanged uncheckedPassword ->
            { model
              | passwordTypedIntoRegister = uncheckedPassword
            }
        
        Register goodPassword ->
            { model
                | passwordTypedIntoRegister = tag ""
                , loggedIn =
                    LoggedIn { userPassword = goodPassword }
            }

view { passwordTypedIntoRegister } =
    Html.div []
        [ Html.div [] [ text "register" ]
        , Html.input
            [ onInput (tag >> PasswordTypedIntoRegisterChanged)
                --not accessible from now on
            , value (Password.toOnlyDots passwordTypedIntoRegister)
            ]
            []
        , case Password.isGood passwordTypedIntoRegister of
            Ok goodPassword ->
                Html.button
                    [ onClick (Register goodPassword) ]
                    [ text "Create account" ]
            Err message ->
                text message
        ]
```
```elm
leak (Typed.value passwordTypedIntoRegister)
-- or
leak (Typed.value userPassword)
```
→ compile-time error: Can't access the `value` inside a `Hidden...`.

## When not to use `Checked`/`CheckedHidden`

There might be a type that can guarantee these promises even if created by users.

Example `GoodPassword`:

```elm
type alias GoodPassword howMuchLongerThan10 maxLength lengthMaybeN =
    Arr
        (In (Nat10Plus howMuchLongerThan10)
            maxLength
            lengthMaybeN
        )
        Char
```
Used here: [`elm-bounded-array`](https://package.elm-lang.org/packages/lue-bird/elm-bounded-array/latest/).

## Prior art
This package wouldn't exist without a lot of inspiration from those packages.
- [Punie/elm-id](https://package.elm-lang.org/packages/Punie/elm-id/latest/)

especially
- [joneshf/elm-tagged](https://package.elm-lang.org/packages/joneshf/elm-tagged/latest/)
- [IzumiSy/elm-typed](https://package.elm-lang.org/packages/IzumiSy/elm-typed/latest/)
