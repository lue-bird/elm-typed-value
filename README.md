# elm-typed-value

> better 1-constructor types

Similar to [prior art](#prior-art):

A value is wrapped in the `type Typed` with a phantom `tag`.

→ A `Typed ... Meters ... Float` can't be called a `Typed ... Kilos ... Float` anymore!

For `type`s with just one constructor with a value, a `Typed` can be a good replacement ([↑ limits](#limits)).

You get rid of writing and calling different functions for those types:

```elm
extract (Special value) =
    value

map alter (Special value) =
    Special (alter value)

--...

naturalNumber |> NaturalNumber.toInt
height |> Meters.toFloat
oneWeight |> Kilos.map ((+) (Kilos.toFloat otherWeight))
if
    (oneHeight |> Meters.toFloat)
        > (otherHeight |> Meters.toFloat)
then
```

Do you really have to remind yourself every step that you're still operating on `Meters` or `Kilos`? With `Typed`:

```elm
val naturalNumber
val height
Typed.map2 (+) oneWeight otherWeight
if val2 (>) oneHeight otherHeight then
```

There are 2 kinds of `Typed`:

  - `Checked`, if the type should only contain "validated" values

    ```elm
    module NaturalNumber exposing (NaturalNumber)

    type NaturalNumber =
        -- nobody outside this module can call this constructor
        NaturalNumber Int
    ```

    Creating & updating `NaturalNumber`s will only be possible inside that module.

  - `Tagged`, if you just want to attach a label to make 2 values different

    ```elm
    type Cat =
        -- constructor can be used anywhere
        Cat { name : String, mood : Mood }
    ```

    Users can create **& update** new `Cat`s everywhere


Use `Public` to allow users to access the value; use `Internal` to hide it from users.


# examples

```elm
import Typed
    exposing
        ( Typed, Tagged, Public, Checked, Internal
        , tag, isChecked, val, val2, internalVal
        )
```

## `Tagged` + `Public`

```elm
type alias Pet tag specificProperties =
    Typed
        Tagged
        tag 
        Public
        { specificProperties | name : String, mood : Mood }

type alias Cat =
    Pet CatTag { napsPerDay : Float }

type alias Dog =
    Pet DogTag { barksPerDay : Float }

type CatTag
    = Cat Never

type DogTag
    = Dog Never

sit : Dog -> Dog
sit =
    Typed.map (\p -> { p | mood = Neutral })
```

```elm
-- annotate to say it's a Cat
howdy : Cat
howdy =
    tag { name = "Howdy", mood = Happy, napsPerDay = 2.2 }

howdy |> sit -- error
```

Another example:

```elm
type alias Pixels =
    Typed Tagged PixelsTag Public Int

type PixelsTag
    = Pixels Never

-- use a type annotation to say what the result is
ratio : Int -> Int -> ( Pixels, Pixels )
ratio w h =
    ( tag w, tag h )
```

```elm
defaultWindowWidth : Pixels
defaultWindowWidth =
    Typed.map2 (+)
        innerWindowWidth
        (borderWidth |> Typed.map ((*) 2))

-- annotate to say it's in Pixels
innerWindowWidth : Pixels
innerWindowWidth =
    tag 700

-- annotate to say it's in Pixels
borderWidth : Pixels
borderWidth =
    tag 5

val defaultWindowWidth
--> 710
```

## `Checked` + `Public`

```elm
module Even exposing
    ( Even, zero, two
    , multiply, add
    )

type alias Even =
    Typed Checked EvenTag Public Int

type EvenTag
    -- don't expose this constructor
    = Even

multiply : Int -> Even -> Even
multiply int =
    Typed.map ((*) int) >> isChecked Even

add : Even -> Even -> Even
add toAdd =
    Typed.map2 (+) toAdd >> isChecked Even

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
--> compile-time error: isn't of type Typed Checked ...

cakeForEvenNumbers
    (Even.two |> Even.multiply -5)
--> Cake
```

## `Checked` + `Internal`

A validated value that can't be directly accessed by a user.

A module that only exposes randomly generated unique `Id`s:

```elm
module Id exposing (Id, random, toBytes, toString)

import Random

type alias Id =
    Typed Checked IdTag Internal String

type IdTag = Id

random : Random.Generator Id
random =
    Random.list 16 ({-...-})
        |> Random.map String.fromList
        |> Random.map (isChecked Id)

-- the API stays the same even if the implementation changes
toBytes --...
toString --...
```
No `Id` can be created outside this package!

## Combined with `Tagged` + `Internal`

```elm
module Password exposing (UncheckedPassword, GoodPassword, isGood, toOnlyDots)

type alias Password goodOrUnchecked =
    Typed goodOrUnchecked PasswordTag Internal String

type PasswordTag
    = -- don't expose the tag constructor
      Password

type alias GoodPassword =
    Password Checked

type alias UncheckedPassword =
    Password Tagged


isGood : UncheckedPassword -> Result String GoodPassword
isGood passwordToTest =
    let
        passwordString =
            internalVal Password passwordToTest
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
toOnlyDots : Password goodOrUnchecked_ -> String
toOnlyDots =
    internalVal Password
        >> String.length
        >> (\length -> String.repeat length '·')
```
In another module
```elm
type alias Model =
    { -- cannot access the password the user typed
      passwordTypedIntoRegister : UncheckedPassword
    , loggedIn : LoggedIn
    }

type LoggedIn
    = -- there can't be a user with a bad password
      LoggedIn { userPassword : GoodPassword }
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
        [ Html.div [] [ Html.text "register" ]
        , Html.input
            [ onInput
                --not accessible from now on
                (tag >> PasswordTypedIntoRegisterChanged)
            , Html.value (Password.toOnlyDots passwordTypedIntoRegister)
            ]
            []
        , case Password.isGood passwordTypedIntoRegister of
            Ok goodPassword ->
                Html.button
                    [ onClick (Register goodPassword) ]
                    [ Html.text "Create account" ]
                
            Err message ->
                text message
        ]
```
```elm
leak (val passwordTypedIntoRegister)
-- or
leak (val userPassword)
```
→ compile-time error: Can't access the value inside a `Internal`.

## When not to use `Checked`

There might be a type that can guarantee these promises even if created by users.

Example `GoodPassword`:

```elm
type alias GoodPassword =
    Arr (Min Nat10) Char
```
Used: [`elm-typesafe-array`](https://package.elm-lang.org/packages/lue-bird/elm-typesafe-array/latest/).

# prior art

This package wouldn't exist without a lot of inspiration from those packages.
- [Punie/elm-id](https://package.elm-lang.org/packages/Punie/elm-id/latest/)

especially
- [joneshf/elm-tagged](https://package.elm-lang.org/packages/joneshf/elm-tagged/latest/)
- [IzumiSy/elm-typed](https://package.elm-lang.org/packages/IzumiSy/elm-typed/latest/)

# limits

1. If the internal value changes that's considered a breaking change.
2. `Typed` sadly can't replace `type`s when defining recursive types:

    ```elm
    type alias Comment =
        Typed
            Tagged
            CommentTag
            Public
            { message : String
            , responses : List Comment
            }
    ```
    elm:
    > This type alias is recursive, forming an infinite type.

    [recursive alias hint](https://github.com/elm/compiler/blob/master/hints/recursive-alias.md):
    > Somewhere in that cycle, you need to define an actual type to end the infinite expansion.

    My answer: use a tree like [zwilias/elm-rosetree](https://package.elm-lang.org/packages/zwilias/elm-rosetree/latest/Tree):

    ```elm
    type alias Comments =
        Maybe (Tree { message : String })
    ```

    From the outside, recursive aliases seem like a solvable problem at the language level.
    Let's watch how elm handles them in the future.
