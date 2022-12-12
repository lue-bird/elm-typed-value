# elm-typed-value

> type with 1 variant → save boilerplate safely

Wrap your thing in a [`Typed`](Typed#Typed) with a `tag` (↑ [prior art](#prior-art)).

→ A `Typed ... Meters ... Float` isn't accepted as `Typed ... Kilos ... Float` anymore!

For `type`s with just one variant with an attached thing, `Typed` can be a convenient replacement (↑ [limits](#limits))

with `type`
```elm
extract =
    \(Meters value) ->
        value

map alter =
    \(Meters value) ->
        value |> alter |> Meters
```
and other helpers like map2 etc. are all covered by [`Typed`](Typed#Typed)
```elm
3.2 |> Meters.fromFloat

naturalNumber |> NumberNatural.toInt
height |> Meters.toFloat

(oneHeight |> Meters.toFloat)
    + (otherHeight |> Meters.toFloat)
    |> Meters.fromFloat
```

with `Typed`

```elm
3.2 |> tag Meters

naturalNumber |> untag
height |> untag

oneHeight
    |> Typed.and otherHeight
    |> Typed.map (\( h0, h1 ) -> h0 + h1)
```

# Kinds of [`Typed`](Typed#Typed)

  - [`Checked`](Typed#Checked) → only "validated" values
    ```elm
    module NumberNatural exposing (NumberNatural)

    type NumberNatural
        -- nobody outside this module can call this constructor
        = NumberNatural Int
    ```
    creating & altering `NumberNatural`s will only be possible inside that `module`

  - [`Tagged`](Typed#Tagged) → attach a label
    ```elm
    type Cat =
        -- constructor can be used anywhere
        Cat { name : String, mood : Mood }
    ```
    Users can create **& alter** new `Cat`s everywhere

  - [`Public`](Typed#Public) → allow users to access (→ [`untag`](Typed#untag)) the value

  - [`Internal`](Typed#Internal) → hide the value from users

## [`Tagged`](Typed#Tagged) [`Public`](Typed#Public)

```elm
import Typed exposing (Typed, Tagged, Public, tag)

type alias Pet tag specificProperties =
    Typed
        Tagged
        tag 
        Public
        { specificProperties | name : String, mood : Mood }

type alias Cat =
    Pet CatTag { napsPerDay : Float }

type CatTag
    = Cat

type alias Dog =
    Pet DogTag { barksPerDay : Float }

type DogTag
    = Dog

sit : Dog -> Dog
sit =
    Typed.map (\d -> { d | mood = Neutral })
```

```elm
howdy =
    { name = "Howdy", mood = Happy, napsPerDay = 2.2 }
        |> tag Cat

howdy |> sit -- error
```

Another example:

```elm
module Pixels exposing (Pixels, PixelsTag(..), ratio)

import Typed exposing (Typed, Tagged, Public, tag)

type alias Pixels =
    Typed Tagged PixelsTag Public Int

type PixelsTag
    = Pixels

-- in another module using Pixels

innerWidth : Pixels
innerWidth =
    700 |> tag Pixels

borderWidth : Pixels
borderWidth =
    5 |> tag Pixels

defaultWidth : Pixels
defaultWidth =
    innerWidth
        |> Typed.and borderWidth
        |> Typed.map
            (\( inner, border ) -> inner + border * 2)

defaultWidth |> Typed.untag
--> 710
```

## [`Checked`](Typed#Checked) [`Public`](Typed#Public)

```elm
module Even exposing (Even, add, multiply, n0, n2)

import Typed exposing (Typed, Checked, Public, tag)


type alias Even =
    Typed Checked EvenTag Public Int


-- don't expose(..) its variant
type EvenTag
    = Even


multiply : Int -> Even -> Even
multiply factor =
    \even ->
        even
            |> Typed.map (\int -> int * factor)
            |> Typed.isChecked Even


add : Even -> Even -> Even
add toAddEven =
    \even ->
        even
            |> Typed.and toAddEven
            |> Typed.map
                (\( int, toAddInt ) -> int + toAddInt)
            |> Typed.isChecked Even


n0 : Even
n0 =
    0 |> tag Even


n2 : Even
n2 =
    2 |> tag Even

-- in another module using Even

cakeForEven : Even -> { cake : () }
cakeForEven _ =
    { cake = () }

n0 |> Typed.map (\n -> n + 1) |> cakeForEven
--→ compile-time error: is Tagged but expected Checked

n2 |> multiply -5 |> cakeForEven
--> { cake = () }
```

## [`Checked`](Typed#Checked) [`Internal`](Typed#Internal)

A validated value that can't be directly accessed by a user.

A module that only exposes randomly generated unique `Id`s:

```elm
module Id exposing (Id, random, toBytes, toString)

import Typed exposing (Typed, Checked, Internal, tag)


import Random

type alias Id =
    Typed Checked IdTag Internal (List Int)

type IdTag = Id

random : Random.Generator Id
random =
    Random.list 2
        (Random.int Random.minInt Random.maxInt)
        |> Random.map (tag Id)

-- the API stays the same even if the implementation changes
toBytes --...
toString --...
```
→ Outside of this module, the only way to create an `Id` is `Id.random`

## Combined with [`Tagged`](Typed#Tagged) [`Internal`](Typed#Internal)

```elm
module Password exposing (PasswordUnchecked, PasswordGood, check, length, unchecked)

import Typed exposing (Typed, Tagged, Checked, Internal, tag, internal)


type alias Password goodOrUnchecked =
    Typed goodOrUnchecked PasswordTag Internal String

type PasswordTag
    = -- don't expose the tag constructor
      Password

type alias PasswordGood =
    Password Checked

type alias PasswordUnchecked =
    Password Tagged

-- ! annotates the result as `Tagged` ↓
unchecked : String -> PasswordUnchecked
unchecked =
    tag Password

check : PasswordUnchecked -> Result String PasswordGood
check =
    \passwordToTest ->
        let
            passwordString =
                passwordToTest |> internal Password
        in
        if (passwordString |> String.length) < 10 then
            Err "Use at lest 10 letters & symbols."

        else if commonPasswords |> Set.member passwordString then
            Err "Choose a less common password."

        else
            passwordToTest |> Typed.isChecked Password |> Ok

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
length : Password goodOrUnchecked_ -> Int
length =
    \password ->
        password
            |> internal Password
            |> String.length
```

```elm
module Register exposing (Model, Event, ui, reactTo, modelInitial)

import Password exposing (PasswordUnchecked)

type alias Model =
    { -- accessing user-typed password is impossible
      passwordTyped : PasswordUnchecked
    , loggedIn : LoggedIn
    }

modelInitial : Model
modelInitial =
    { passwordTyped =
        "" |> Password.unchecked
    , loggedIn = NotLoggedIn
    }

type LoggedIn
    = -- no user can have an unchecked password
      LoggedIn { userPassword : PasswordGood }
    | NotLoggedIn


type Event
    = PasswordEdited PasswordUnchecked
    | PasswordConfirmed PasswordGood

reactTo : Event -> Model -> Model
reactTo event =
    \model ->
        case event of
            PasswordEdited uncheckedPassword ->
                { model
                    | passwordTyped = uncheckedPassword
                }
            
            PasswordConfirmed passwordGood ->
                { model
                    | passwordTyped =
                        "" |> Password.unchecked
                    , loggedIn =
                        LoggedIn { userPassword = passwordGood }
                }

ui =
    \{ passwordTyped } ->
        [ [ "register" |> Html.text ] |> Html.div []
        , Html.input
            [ onInput
                (\text ->
                    text
                        |> Password.unchecked
                        -- not accessible from now on
                        |> PasswordEdited
                )
            , String.repeat
                (passwordTyped
                    |> Password.length
                )
                "·"
                |> Html.value
            ]
            []
        , case passwordTyped |> Password.check of
            Ok passwordGood ->
                Html.button
                    [ onClick (PasswordConfirmed passwordGood) ]
                    [ "Create account" |> Html.text ]
                
            Err message ->
                message |> Html.text
        ]
            |> Html.div []
```
```elm
passwordTyped |> untag |> leak
userPassword |> untag |> leak
```
→ compile-time error: expected `Public` but found `Internal`

## narrow type > > [`Checked`](Typed#Checked)

More often than not,
there's already a type with the same promises
even when created directly by users:

```diff
type alias StringFilled =
-    Typed Checked StringFilledTag Public String
+    Hand { head : Char, tail : String } Never Empty

type alias PasswordGoodInternal =
-    String
+    Arr (Min Nat10) Char
```
Used here:

  - [`typesafe-array`](https://package.elm-lang.org/packages/lue-bird/elm-typesafe-array/latest/)
  - [`emptiness-typed`](https://dark.elm.dmy.fr/packages/lue-bird/elm-emptiness-typed/latest/)


# prior art

This package wouldn't exist without inspiration:

  - [`Punie/elm-id`](https://package.elm-lang.org/packages/Punie/elm-id/latest/)

especially
  - [`joneshf/elm-tagged`](https://package.elm-lang.org/packages/joneshf/elm-tagged/latest/)
  - [`IzumiSy/elm-typed`](https://package.elm-lang.org/packages/IzumiSy/elm-typed/latest/)


# limits

## changing a [`Checked`](Typed#Checked) [`Internal`](Typed#Internal) value is a major change

For many this might be a deal-breaker.

Be explicit and choose a `type` for parts of information that could be added or removed in the future.

## can't be defined recursively

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

In this instance: try tree structures like [`zwilias/elm-rosetree`](https://package.elm-lang.org/packages/zwilias/elm-rosetree/latest/Tree):

```elm
type alias Comments =
    Maybe (Tree { message : String })
```

From the outside, recursive aliases seem like a problem solvable at the language level.
Let's watch how elm handles them in the future.
