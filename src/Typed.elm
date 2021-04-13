module Typed exposing
    ( Typed, NoUser, Anyone
    , tag, Tagged, serialize
    , Checked, isChecked
    , value, values2, hiddenValueIn
    , TaggedHidden, CheckedHidden
    , map, map2
    )

{-|


## building blocks

@docs Typed, NoUser, Anyone


## created by anyone

@docs tag, Tagged, serialize


## checked

@docs Checked, isChecked


## access

@docs value, values2, hiddenValueIn


## hidden

@docs TaggedHidden, CheckedHidden


## modify

@docs map, map2

-}

import Serialize


{-| A value is wrapped in a `type` with a phantom `tag`,
so that a `Typed A Int ...` is not a `Typed B Int ...`.

The wrappers of type `Typed`

  - [`Checked`](Typed#Checked)

  - [`Tagged`](Typed#Tagged)

  - [`TaggedHidden`](Typed#TaggedHidden)

  - [`CheckedHidden`](Typed#TaggedHidden)

all promise additional type-safety.

You will see `Typed` as a function argument type.

    map :
        (value -> mappedValue)
        -> Typed tag value { whoCanAccess | createdBy : whoCreated }
        -> Typed mappedTag mappedValue { whoCanAccess | createdBy : Anyone }

Is saying: `map` works on every `Typed`.
The result has the same one `whoCreated` it.

Meaning if the input was

  - `Checked` or `Tagged`, the result becomes a `Tagged`
  - `CheckedHidden` or `TaggedHidden`, the result becomes a `TaggedHidden`

-}
type Typed tag value whoCreatedAndWhoCanAccess
    = Typed value


{-| Create a new tagged value.

  - can be `Checked` with [`isChecked`](Typed#isChecked)
  - if you start modifying that value, it becomes a `Tagged`
  - becomes a `TaggedHidden` when annotated / used as an argument

-}
tag : value -> Typed tag value { whoCanAccess | createdBy : Anyone }
tag value_ =
    Typed value_


{-| Anyone who wanted.
-}
type Anyone
    = Anyone Never


{-| Only the ones with access to the `tag` constructor.
-}
type NoUser
    = NoUser Never


{-| Every possible `value` can be described with this `tag`.

  - `Tagged MetersTag Float`
      - **✓** Every Float can describe `Meters`
  - `Tagged NaturalNumberTag Int`
      - **⨯ Not** every `Int` can be called a `NaturalNumber`
      - Use [`Checked`](Typed#Checked) instead!

Anyone can access its `value`.

Instances can be created & updated everywhere.

-}
type alias Tagged tag value =
    Typed
        tag
        value
        { canAccess : Anyone
        , createdBy : Anyone
        }



-- ## access


{-| Instances that are validated from inside the module where the `tag` is.

Anyone can read the valid `value`, but once you modify it, it just becomes a `Tagged`.

-}
type alias Checked tag value =
    Typed
        tag
        value
        { canAccess : Anyone
        , createdBy : NoUser
        }


{-| Read the value inside a `Tagged` or `Checked`.
-}
value :
    Typed tag value { whoCreated | canAccess : Anyone }
    -> value
value =
    \(Typed value_) -> value_


{-| Use the values of 2 `Accessible`s to return a result.

    type alias PrimeNumber =
        Checked PrimeNumberTag Int

    prime3 : PrimeNumber
    prime3 =
        tag 3 |> isChecked PrimeNumber

    prime5 =
        tag 5 |> isChecked PrimeNumber

Anywhere

    Typed.values2 (+) prime3 prime5
    --> 8

    Typed.values2 Tuple.pair prime3 prime5
    --> ( 3, 5 )

-}
values2 :
    (aValue -> bValue -> resultValue)
    -> Typed aTag aValue { whoCreateda | canAccess : Anyone }
    -> Typed bTag bValue { whoCreatedb | canAccess : Anyone }
    -> resultValue
values2 binOp aTyped bTyped =
    binOp (value aTyped) (value bTyped)


{-| After calling `tag` or modifying a checked value, you get a `Tagged`. To tell the type that the result value is `Checked`, use `isChecked tag`.

The type of `tag` might even change in that operation.

    oddPlusOdd : Odd -> Odd -> Even
    oddPlusOdd oddToAdd =
        Typed.map2 (+) oddToAdd
            >> isChecked Even

-}
isChecked :
    checkedTag
    -> Typed tag value { whoCanAccess | createdBy : whoCreated }
    -> Typed checkedTag value { whoCanAccess | createdBy : NoUser }
isChecked _ =
    \(Typed value_) -> Typed value_



-- ## no need to check


{-| Using its value isn't allowed.

    type alias Password =
        TaggedHidden PasswordTag String

    type PasswordTag
        = Password Never

    type alias User =
        { password : Password

        --...
        }

    showUsYourPassword user =
        -- compile-time error
        user.password |> Typed.value

The only thing you can still use is `==` on 2 `TaggedHidden`s of the same type.

-}
type alias TaggedHidden tag value =
    Typed
        tag
        value
        { createdBy : Anyone
        , canAccess : NoUser
        }


{-| Alter the value inside.

If the `Typed` was a `Checked`, it becomes a `Typed`.

    type alias Meters =
        Typed MetersTag Int Typed

    type alias Millimeters =
        Typed MilliMetersTag Typed

    go1km : Meters -> Meters
    go1km =
        Typed.map ((+) 1000)

-}
map :
    (value -> mappedValue)
    -> Typed tag value { whoCanAccess | createdBy : whoCreated }
    -> Typed mappedTag mappedValue { whoCanAccess | createdBy : Anyone }
map alter =
    \(Typed value_) -> alter value_ |> Typed


{-| Use the values of 2 `Typed`s to return a result.

The result becomes a `CreatableAndModifiable` with the same reading permission as the 2 inputs.

    type alias PrimeNumber =
        Typed PrimeNumberTag Int Checked

    prime3 : PrimeNumber
    prime3 =
        tag 3 |> isChecked PrimeNumber

    prime5 =
        tag 5 |> isChecked PrimeNumber

Anywhere

    Typed.values2 (+) prime3 prime5
    --> 8

In another module

    type alias NonPrime =
        Checked NonPrimeTag Int

    fromMultiplyingPrimes aPrime bPrime =
        Typed.map2 (*) aPrime bPrime
            |> isChecked NonPrime

-}
map2 :
    (aValue -> bValue -> combinedValue)
    -> Typed aTag aValue { whoCanAccess | createdBy : aWhoCanCreate }
    -> Typed bTag bValue { whoCanAccess | createdBy : bWhoCanCreate }
    -> Typed combinedTag combinedValue { whoCanAccess | createdBy : Anyone }
map2 binOp aTyped bTyped =
    let
        (Typed aValue) =
            aTyped

        (Typed bValue) =
            bTyped
    in
    binOp aValue bValue |> Typed



-- ## hidden


{-| A `Checked` value, but not everything about the `value` is exposed. This allows

  - hiding implementation details
  - hiding data you don't want users to see

-}
type alias CheckedHidden tag value =
    Typed
        tag
        value
        { createdBy : NoUser
        , canAccess : NoUser
        }


{-| If you have a `CheckedHidden`, its value isn't readable by users.

If you have the `tag` however, you can access this data hidden from the user.

-}
hiddenValueIn :
    tag
    -> Typed tag value { whoCreated | canAccess : NoUser }
    -> value
hiddenValueIn _ =
    \(Typed value_) -> value_


serialize :
    Serialize.Codec error value
    -> Serialize.Codec error (Tagged tag value)
serialize serializeValue =
    serializeValue
        |> Serialize.map tag value
