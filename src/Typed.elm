module Typed exposing
    ( Typed
    , Tagged, tag, map, map2
    , Checked, isChecked
    , Public, val, val2
    , Internal, internalVal, internalVal2
    , serialize, serializeChecked
    )

{-|

@docs Typed


## who can create


### tagged

@docs Tagged, tag, map, map2


### checked

@docs Checked, isChecked


## who can access


### Public

@docs Public, val, val2


### internal

@docs Internal, internalVal, internalVal2


## serialize

@docs serialize, serializeChecked

-}

import Serialize


{-| A value is wrapped in the `type Typed` with a phantom `tag`.

A `Typed ... Meters ... Float` can't be called a `Typed ... Kilos ... Float` anymore!

For `type`s with just 1 constructor with a value a `Typed` can be a good replacement.


### who can construct such a value

  - [`Checked`](Typed#Checked)

  - [`Tagged`](Typed#Tagged)


### who can access the value

  - [`Public`](Typed#Public)

  - [`Internal`](Typed#Internal)

all promise additional type-safety.


### reading types

    map :
        (value -> mappedValue)
        -> Typed whoCanCreate tag whoCanAccess value
        -> Typed Tagged tag whoCanAccess

Is saying: `map` works on every `Typed` and returns a value that is just `Tagged`, but not `Checked`.
Explaining `whoCanAccess`:

  - If the input is `Public`
  - If the input is `Internal`,

the result will be too.

-}
type Typed whoCreated tag whoCanAccess value
    = Typed value


{-| Only the ones with access to the `tag` constructor can access the `Typed.internalVal`.

Meaning that access can be limited to

  - inside a module

```
module Special exposing (Special)

type alias Special =
    Typed Tagged SpecialTag Internal SpecialValue
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
        Typed Checked OptimizedListTag Internal (Implementation a)

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

Example `Typed Tagged MetersTag ... Float`

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

  - can be `Checked` with [`isChecked`](Typed#isChecked)
  - becomes `Internal/Public` when annotated that way

Modifying won't change the type.

-}
tag : value -> Typed Tagged tag whoCanAccess value
tag value_ =
    Typed value_



-- ## access


{-| Read the value inside a `Public` `Typed`.
-}
val : Typed whoCreated tag Public value -> value
val =
    \(Typed value_) -> value_


{-| Use the values of 2 `Public` `Typed`s to return a result.

    type alias Prime =
        Typed Checked PrimeTag Public Int

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
    -> Typed whoCreatedA aTag Public aValue
    -> Typed whoCreatedB bTag Public bValue
    -> resultValue
val2 binOp aTyped bTyped =
    binOp (val aTyped) (val bTyped)


{-| After calling `tag` or modifying a checked value, you get a `Tagged`. To tell the type that the result value is `Checked`, use `isChecked tag`.

The type of `tag` might even change in that operation.

    oddPlusOdd : Odd -> Odd -> Even
    oddPlusOdd oddToAdd =
        Typed.map2 (+) oddToAdd
            >> isChecked Even

-}
isChecked :
    checkedTag
    -> Typed whoCreated tag whoCanAccess value
    -> Typed Checked checkedTag whoCanAccessChecked value
isChecked _ =
    \(Typed value_) -> Typed value_



-- ## no need to check


{-| Alter the value inside.

If the `Typed` was a `Checked`, it becomes a `Tagged`.

    type alias Meters =
        Typed Tagged MetersTag Public Int

    go1km : Meters -> Meters
    go1km =
        Typed.map ((+) 1000)

-}
map :
    (value -> mappedValue)
    -> Typed whoCreated tag whoCanAccess value
    -> Typed Tagged tag whoCanAccess mappedValue
map alter =
    \(Typed value_) -> alter value_ |> Typed


{-| Use the values of 2 `Typed`s to return a `Tagged` result.

    type alias PrimeNumber =
        Typed Checked PrimeNumberTag Public Int

    prime3 : PrimeNumber
    prime3 =
        tag 3 |> isChecked PrimeNumber

    prime5 =
        tag 5 |> isChecked PrimeNumber

In another module

    type alias NonPrime =
        Typed Checked NonPrimeTag Public Int

    fromMultiplyingPrimes : Prime -> Prime -> NonPrime
    fromMultiplyingPrimes aPrime bPrime =
        Typed.map2 (*) aPrime bPrime
            |> isChecked NonPrime

-}
map2 :
    (value -> value -> mappedValue)
    -> Typed whoCanCreateA tag whoCanAccess value
    -> Typed whoCanCreateB tag whoCanAccess value
    -> Typed Tagged tag whoCanAccess mappedValue
map2 binOp aTyped bTyped =
    let
        (Typed aValue) =
            aTyped

        (Typed bValue) =
            bTyped
    in
    binOp aValue bValue |> Typed


{-| If you have an `Internal`, its value isn't readable by users.

If you have the `tag` however, you can access this data hidden from users.

-}
internalVal :
    tag
    -> Typed whoCanCreate tag Internal value
    -> value
internalVal _ =
    \(Typed value_) -> value_


{-| Use the values of 2 `Internal` `Typed`s to return a result.

    type alias OptimizedList a =
        Typed
            Checked
            OptimizedListTag
            Internal
            { list : List a, length : Int }

    type OptimizedListTag
        = OptimizedList

    equal a b =
        internalVal2 (==) OptimizedList a OptimizedList b

-}
internalVal2 :
    (aValue -> bValue -> resultValue)
    -> aTag
    -> Typed whoCreatedA aTag Internal aValue
    -> bTag
    -> Typed whoCreatedB bTag Internal bValue
    -> resultValue
internalVal2 binOp aTag aTyped bTag bTyped =
    binOp (internalVal aTag aTyped) (internalVal bTag bTyped)


{-| A [`Codec`](https://package.elm-lang.org/packages/MartinSStewart/elm-serialize/latest/) to serialize `Tagged` `Public` `Typed`s.
-}
serialize :
    Serialize.Codec error value
    -> Serialize.Codec error (Typed Tagged tag Public value)
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
            |> Typed.serializeChecked Nat
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
        Typed Checked EfficientListTag
            Internal { list : List a, length : Int }

    serialize =
        Serialize.map .list identity
            |> Serialize.list
            |> Typed.serializeChecked EfficientList
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
            (Typed Checked tag whoCanAccess value)
serializeChecked tag_ checkValue serializeValue =
    serializeValue
        |> Serialize.mapValid
            (checkValue >> Result.map (tag >> isChecked tag_))
            (\(Typed value_) -> value_)
