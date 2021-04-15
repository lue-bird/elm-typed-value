module Val exposing
    ( Val
    , Tagged, tag, map, map2
    , Checked, isChecked
    , Public, val, val2
    , Internal, internal
    , serialize, serializeChecked
    )

{-|

@docs Val


## who can create


### tagged

@docs Tagged, tag, map, map2


### checked

@docs Checked, isChecked


## who can access


### Public

@docs Public, val, val2


### internal

@docs Internal, internal


## serialize

@docs serialize, serializeChecked

-}

import Serialize


{-| A value is wrapped in the `type Val` with a phantom `tag`.

A `Val ... Meters ... Float` can't be called a `Val ... Kilos ... Float` anymore!

For `type`s with just 1 constructor with a value a `Val` can be a good replacement.


### who can construct such a value

  - [`Checked`](Val#Checked)

  - [`Tagged`](Val#Tagged)


### who can access the value

  - [`Public`](Val#Public)

  - [`Internal`](Val#Internal)

all promise additional type-safety.


### reading types

    map :
        (value -> mappedValue)
        -> Val whoCanCreate tag whoCanAccess value
        -> Val Tagged tag whoCanAccess

Is saying: `map` works on every `Val` and returns a value that is just `Tagged`, but not `Checked`.
Explaining `whoCanAccess`:

  - If the input is `Public`
  - If the input is `Internal`,

the result will be too.

-}
type Val whoCreated tag whoCanAccess value
    = Val value


{-| Only the ones with access to the `tag` constructor can access the `Val.internal`.

Meaning that access can be limited to

  - inside a module

```
module Special exposing (Special)

type alias Special =
    Val Tagged SpecialTag Internal SpecialValue
```

  - inside a package (only with `Checked`)

```
src
  └ Special
      └ Internal.elm
          module Special.Internal exposing (SpecialTag(..))
  └ SpecialPartA.elm
      module SpecialPartA exposing (SpecialPartA)
      import Special.Internal exposing (SpecialTag(..))
  └ SpecialPartB.elm
      module SpecialPartB exposing (SpecialPartB)
      import Special.Internal exposing (SpecialTag(..))
elm.json 'exposed-modules' :
  [ "SpecialPartA", "SpecialPartB" ]
```

This generally helps hiding implementation details.

    type alias OptimizedList a =
        Val Checked OptimizedListTag Internal (Implementation a)

    type alias Implementation a =
        { list : List a, length : Int }

    toList --...

-}
type Internal
    = Internal Never


{-| Anyone is able to access the value.
-}
type Public
    = Public Never


{-| Anyone is able to create one of those.

Example `Val Tagged MetersTag ... Float`

→ The right choice, as every `Float` is a valid description of `Meters`

-}
type Tagged
    = Tagged Never


{-| Only someone with access to the `tag` constructor is able to create one of those.

In effect, this means that you can only let "validated" data be of this type.

Examaple `... Checked ... NaturalNumberTag Int`

→ **✓** not every `Int` can be called a `NaturalNumber`, it must be checked!

-}
type Checked
    = Checked Never


{-| Create a new tagged value.

  - can be `Checked` with [`isChecked`](Val#isChecked)
  - becomes `Internal/Public` when annotated that way

Modifying won't change the type.

-}
tag : value -> Val Tagged tag whoCanAccess value
tag value_ =
    Val value_



-- ## access


{-| Read the value inside a `Public` `Val`.
-}
val : Val whoCreated tag Public value -> value
val =
    \(Val value_) -> value_


{-| Use the values of 2 `Accessible`s to return a result.

    type alias Prime =
        Val Checked PrimeTag Public Int

    prime3 =
        tag 3 |> isChecked Prime

    prime5 =
        tag 5 |> isChecked Prime

Anywhere

    val2 (+) prime3 prime5
    --> 8

    val2 Tuple.pair prime3 prime5
    --> ( 3, 5 )

    if val2 (<) onePrime otherPrime then

-}
val2 :
    (aValue -> bValue -> resultValue)
    -> Val whoCreatedA aTag Public aValue
    -> Val whoCreatedB bTag Public bValue
    -> resultValue
val2 binOp aTyped bTyped =
    binOp (val aTyped) (val bTyped)


{-| After calling `tag` or modifying a checked value, you get a `Tagged`. To tell the type that the result value is `Checked`, use `isChecked tag`.

The type of `tag` might even change in that operation.

    oddPlusOdd : Odd -> Odd -> Even
    oddPlusOdd oddToAdd =
        Val.map2 (+) oddToAdd
            >> isChecked Even

-}
isChecked :
    checkedTag
    -> Val whoCreated tag whoCanAccess value
    -> Val Checked checkedTag whoCanAccessChecked value
isChecked _ =
    \(Val value_) -> Val value_



-- ## no need to check


{-| Alter the value inside.

If the `Val` was a `Checked`, it becomes a `Tagged`.

    type alias Meters =
        Val Tagged MetersTag Public Int

    go1km : Meters -> Meters
    go1km =
        Val.map ((+) 1000)

-}
map :
    (value -> mappedValue)
    -> Val whoCreated tag whoCanAccess value
    -> Val Tagged tag whoCanAccess mappedValue
map alter =
    \(Val value_) -> alter value_ |> Val


{-| Use the values of 2 `Val`s to return a result. The result becomes a `Tagged`.

    type alias PrimeNumber =
        Val Checked PrimeNumberTag Public Int

    prime3 : PrimeNumber
    prime3 =
        tag 3 |> isChecked PrimeNumber

    prime5 =
        tag 5 |> isChecked PrimeNumber

In another module

    type alias NonPrime =
        Val Checked NonPrimeTag Public Int

    fromMultiplyingPrimes : Prime -> Prime -> NonPrime
    fromMultiplyingPrimes aPrime bPrime =
        Val.map2 (*) aPrime bPrime
            |> isChecked NonPrime

-}
map2 :
    (aValue -> bValue -> combinedValue)
    -> Val whoCanCreateA aTag whoCanAccess aValue
    -> Val whoCanCreateB bTag whoCanAccess bValue
    -> Val Tagged combinedTag whoCanAccess combinedValue
map2 binOp aTyped bTyped =
    let
        (Val aValue) =
            aTyped

        (Val bValue) =
            bTyped
    in
    binOp aValue bValue |> Val


{-| If you have an `Internal`, its value isn't readable by users.

If you have the `tag` however, you can access this data hidden from users.

-}
internal :
    tag
    -> Val whoCanCreate tag Internal value
    -> value
internal _ =
    \(Val value_) -> value_


{-| A [`Codec`](https://package.elm-lang.org/packages/MartinSStewart/elm-serialize/latest/) to serialize `Tagged` `Public` `Val`s.
-}
serialize :
    Serialize.Codec error value
    -> Serialize.Codec error (Val Tagged tag Public value)
serialize serializeValue =
    serializeValue
        |> Serialize.map tag val


{-| A [`Codec`](https://package.elm-lang.org/packages/MartinSStewart/elm-serialize/latest/) to serialize `Checked`s.

We don't trust that the values we encode still have the same promises as our `Checked`s.

Choose a value it can convert from & to and serialize that.

    module Nat exposing (serialize)

    type NatTag
        = Nat

    serialize =
        Serialize.int
            |> Val.serializeChecked Nat
                (\int ->
                    if int >= 0 then
                        Ok int

                    else
                        Err "Int was negative, so it couldn't be decoded as a Nat"
                )

    module EfficientList exposing (serialize)

    type EfficientListTag
        = EfficientList

    type alias EfficientList =
        Val Checked EfficientListTag
            Internal { list : List a, length : Int }

    serialize =
        Serialize.map .list identity
            |> Serialize.list
            |> Val.serializeChecked EfficientList
                (\list ->
                    { list = list
                    , length = List.length length
                    }
                        |> Ok
                )

-}
serializeChecked :
    tag
    -> (value -> Result error value)
    -> Serialize.Codec error value
    ->
        Serialize.Codec
            error
            (Val Checked tag whoCanAccess value)
serializeChecked tag_ checkValue serializeValue =
    serializeValue
        |> Serialize.mapValid
            (checkValue >> Result.map (tag >> isChecked tag_))
            (\(Val value_) -> value_)
