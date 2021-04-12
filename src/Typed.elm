module Typed exposing
    ( Typed, NoUser, Anyone
    , tag
    , Tagged
    , Checked, isChecked
    , TaggedHidden, CheckedHidden, hideValue
    , value, values2, hiddenValueIn
    , map, map2
    )

{-|


## building blocks

@docs Typed, NoUser, Anyone


## create

@docs tag


## no need to check

@docs Tagged


## checked

@docs Checked, isChecked


## hidden

@docs TaggedHidden, CheckedHidden, hideValue


## access

@docs value, values2, hiddenValueIn


## modify

@docs map, map2

-}


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
        -> Typed tag value { whoCanAccess | canCreate : whoCanCreate }
        -> Typed mappedTag mappedValue { whoCanAccess | canCreate : Anyone }

Is saying: `map` works on every `Typed`.
The result is updatable & and has the same permission on `whoCanCreate`.

Meaning if the input was

  - `Checked` or `Tagged`, the result becomes a `Tagged`
  - `CheckedHidden` or `TaggedHidden`, the result becomes a `TaggedHidden`

-}
type Typed tag value accessibilityAndCreatability
    = Typed value


{-| Create a new tagged value.

  - can be `Checked` with [`is`](Typed#is)
  - can be `TaggedHidden` with [`hideValue`](Typed#hideValue)
  - if you start modifying that value, it becomes a `Tagged`

-}
tag : value -> Typed tag value { accessiblility | canCreate : Anyone }
tag value_ =
    Typed value_


{-| Anyone.
-}
type Anyone
    = Anyone Never


{-| Only the ones with access to the `tag` constructor.
-}
type NoUser
    = NoUser Never


{-| Every possible `value` can be a `tag`.

  - Tagged MetersTag Float
      - **✓** Every Float can describe `Meters`
  - Tagged NaturalNumberTag Int
      - **⨯** Not every `Int` can be a `Nat`
      - Use `Checked` instead!

You can ccess its `value`.

An instance can be created & updated everywhere.

-}
type alias Tagged tag value =
    Typed
        tag
        value
        { canAccess : Anyone
        , canCreate : Anyone
        }



-- ## read


{-| Instances that can only be validated in the module where the `tag` is.

You can read the valid `value`, but once you modify it, it just becomes a `Tagged`.

-}
type alias Checked tag value =
    Typed
        tag
        value
        { canAccess : Anyone
        , canCreate : NoUser
        }


{-| Read the value inside the `Accessible`.
-}
value :
    Typed tag value { whoCanCreate | canAccess : Anyone }
    -> value
value =
    \(Typed value_) -> value_


{-| Use the values of 2 `Accessible`s to return a result.

    type alias PrimeNumber =
        Checked PrimeNumberTag Int

    prime3 : PrimeNumber
    prime3 =
        tag PrimeNumber 3

    prime5 =
        tag PrimeNumber 5

Anywhere

    Typed.values2 (+) prime3 prime5
    --> 8

    Typed.values2 Tuple.pair prime3 prime5
    --> ( 3, 5 )

-}
values2 :
    (aValue -> bValue -> resultValue)
    -> Typed aTag aValue { aCreatability | canAccess : Anyone }
    -> Typed bTag bValue { bCreatability | canAccess : Anyone }
    -> resultValue
values2 binOp aTyped bTyped =
    binOp (value aTyped) (value bTyped)


{-| After called `tag` or modified a checked value, you get a `Tagged`. To transform it back, use `isChecked tag`.

The `tag` verifies that you are allowed to say a `value` is `Checked`s with that `tag`.

The type of tag might even change in that operation.

    type alias Length unit =
        Tagged unit Float

    type Meters
        = Meters

    type Millimeters
        = Millimeters

    -- use a type annotation: this should only convert meters
    metersToMillimeters : Length Meters -> Length Millimeters
    metersToMillimeters =
        Typed.map ((*) 1000)
            >> isChecked Millimeters

-}
isChecked :
    checkedTag
    -> Typed tag value { whoCanAccess | canCreate : create }
    -> Typed checkedTag value { whoCanAccess | canCreate : Anyone }
isChecked _ =
    \(Typed value_) -> Typed value_



-- ## creatable by user


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
        { canCreate : Anyone
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
    -> Typed tag value { whoCanAccess | canCreate : whoCanCreate }
    -> Typed mappedTag mappedValue { whoCanAccess | canCreate : Anyone }
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
    -> Typed aTag aValue { whoCanAccess | canCreate : aWhoCanCreate }
    -> Typed bTag bValue { whoCanAccess | canCreate : bWhoCanCreate }
    -> Typed combinedTag combinedValue { whoCanAccess | canCreate : Anyone }
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
        { canCreate : NoUser
        , canAccess : NoUser
        }


{-| Stop users to access to the `value`.

  - A `Checked` becomes a `CheckedHidden`
  - A `Tagged` becomes a `TaggedHidden`

-}
hideValue :
    Typed tag value { whoCanCreate | canAccess : whoCanAccess }
    -> Typed tag value { whoCanCreate | canAccess : NoUser }
hideValue =
    \(Typed value_) -> Typed value_


{-| If you have a `CheckedHidden`, its value isn't readable by users.

If you have the `tag` however, you can access this data hidden from the user.

-}
hiddenValueIn :
    tag
    -> Typed tag value { whoCanCreate | canAccess : NoUser }
    -> value
hiddenValueIn _ =
    \(Typed value_) -> value_
