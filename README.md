# elm-typed-value

> type with 1 variant → save boilerplate safely

Wrap your thing in a [`Typed`](Typed#Typed) with a tag (↑ [prior art](#prior-art)).

→ A `Typed ... Meters ... Float` isn't accepted as `Typed ... Kilos ... Float` anymore!

For `type`s with just one variant with an attached thing,
[`Typed`](Typed#Typed) can be a convenient replacement (↑ [limits](#limits))

with `type`
```elm
extract =
    \(Meters quantity) ->
        quantity

map alter =
    \(Meters quantity) ->
        quantity |> alter |> Meters
```
and other helpers like mapping multiple etc. are all covered by [`Typed`](Typed#Typed)

Plus you don't have to spell out the obvious:
```elm
3.2 |> Meters.fromFloat

prime |> Prime.toInt
height |> Meters.toFloat

(oneHeight |> Meters.toFloat)
    + (otherHeight |> Meters.toFloat)
    |> Meters.fromFloat
```

with [`Typed`](#Typed)

```elm
3.2 |> tag Meters

prime |> untag
height |> untag

oneHeight
    |> Typed.and otherHeight
    |> Typed.map (\( h0, h1 ) -> h0 + h1)
```

# Kinds of [`Typed`](Typed#Typed)

  - [`Checked`](Typed#Checked) → only "validated" things like when you'd use
    ```elm
    module Prime exposing (Prime)

    type Prime
        = -- nobody outside this module can use this variant
          Prime Int
    ```
    creating & altering `Prime`s will only be possible inside that `module`

    An opaque `type` can't expose the variant for destructuring.
    [`Typed`](#Typed) can, as we'll see in [section `Checked Public`](#checked-public).

  - [`Tagged`](Typed#Tagged) → attach a label things like when you'd use
    ```elm
    type Cat
        = -- variant can be used anywhere
          Cat { name : String, mood : Mood }
    ```
    Users can create & alter new `Cat`s everywhere

  - [`Public`](Typed#Public) → allow everyone to access (→ [`untag`](Typed#untag)) the thing

  - [`Internal`](Typed#Internal) → hide from users.
    You can only access the [`internal`](Typed#internal) thing using the tag.

## [`Tagged`](Typed#Tagged) [`Public`](Typed#Public)

```elm
import Typed exposing (Typed, Tagged, Public, tag)

type alias PetData specificProperties =
    { specificProperties | name : String, mood : Mood }

type alias Cat =
    Typed Tagged CatTag Public (PetData { napsPerDay : Float })

type CatTag
    = Cat

type alias Dog =
    Typed Tagged DogTag Public (PetData { barksPerDay : Float })

type DogTag
    = Dog

sit : Dog -> Dog
sit =
    Typed.map (\d -> { d | mood = Neutral })

howdy : Cat
howdy =
    { name = "Howdy", mood = Happy, napsPerDay = 2.2 }
        |> tag Cat

howdy |> sit -- error
```

Another example:

```elm 
module Pixels exposing (Pixels, PixelsTag(..))
```
```elm
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
```
```elm
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
            |> Typed.toChecked Even


add : Even -> Even -> Even
add toAddEven =
    \even ->
        even
            |> Typed.and toAddEven
            |> Typed.map
                (\( int, toAddInt ) -> int + toAddInt)
            |> Typed.toChecked Even


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

A validated thing that can't be directly accessed by a user.

A module that only exposes randomly generated unique `Id`s:

```elm
module Id exposing (Id, random, toBytes, toString)
```
```elm
import Typed exposing (Typed, Checked, Internal, tag)
import Random

type alias Id =
    Typed Checked IdTag Internal (List Int)

type IdTag
    = Id

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
module Password exposing (PasswordUnchecked, PasswordGood, toChecked, length, unchecked)
```
```elm
import Typed exposing (Typed, Tagged, Checked, Internal, tag, internal)

type alias Password goodOrUnchecked =
    Typed goodOrUnchecked PasswordTag Internal String

type PasswordTag
    = -- don't expose the tag variant
      Password

type alias PasswordGood =
    Password Checked

type alias PasswordUnchecked =
    Password Tagged

-- ! annotates the result as `Tagged` ↓
unchecked : String -> PasswordUnchecked
unchecked =
    tag Password

toChecked : PasswordUnchecked -> Result String PasswordGood
toChecked =
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
            passwordToTest |> Typed.toChecked Password |> Ok

commonPasswords =
    Set.fromList
        [ "password1234", "secret1234"
        , "c001_p4ssw0rd", "1234567890"
        --...
        ]
```
You can then decide that only a part of the information should be accessible.
```elm
-- doesn't expose too much information
length : Password goodOrUnchecked_ -> Int
length =
    \password ->
        password
            |> internal Password
            |> String.length
```
used in

```elm
module Register exposing (State, Event, ui, reactTo, stateInitial)
```
```elm
import Password exposing (PasswordUnchecked)

type alias State =
    { -- accessing user-typed password is impossible
      passwordTyped : PasswordUnchecked
    , loggedIn : LoggedIn
    }

stateInitial : State
stateInitial =
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

reactTo : Event -> (Model -> Model)
reactTo event =
    case event of
        PasswordEdited uncheckedPassword ->
            \model ->
                { model
                    | passwordTyped = uncheckedPassword
                }
        
        PasswordConfirmed passwordGood ->
            \model ->
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
        , case passwordTyped |> Password.toChecked of
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

# prior art

This package wouldn't exist without inspiration:

  - [`Punie/elm-id`](https://package.elm-lang.org/packages/Punie/elm-id/latest/)

especially
  - [`joneshf/elm-tagged`](https://package.elm-lang.org/packages/joneshf/elm-tagged/latest/)
  - [`IzumiSy/elm-typed`](https://package.elm-lang.org/packages/IzumiSy/elm-typed/latest/)


# limits

## the type of the [`Public`](#Public) untagged thing is not obvious but used often

In that case expose more descriptive API and leave the rest as "safe internals"!
```elm
toDescriptiveValue : TypedThing -> DescriptiveValue
toDescriptiveValue =
    Typed.internal ThingTag
```
Maybe even make it [`Internal`](Typed#Internal) to not make [`untag`](Typed#untag) available.

## narrow type > [`Checked`](Typed#Checked)

More often than not,
there's already a type with the same promises
even when created directly by users:

```elm
type alias StringFilled =
    Typed Checked StringFilledTag Public String

type alias PasswordLongEnough =
    Typed Checked PasswordLongEnoughTag Public String
```
replaced with
```elm
type alias StringFilled =
    { head : Char, tail : String }

type alias PasswordLongEnough =
    ArraySized (Min (Fixed N10)) Char
```
Here using [`typesafe-array`](https://package.elm-lang.org/packages/lue-bird/elm-typesafe-array/latest/)

Use those! Extensively. No opaque type or Checked necessary

## changing a [`Checked`](Typed#Checked) [`Internal`](Typed#Internal) thing is a major change

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
