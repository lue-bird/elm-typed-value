module Typed exposing
    ( Typed
    , Tagged, tag, map, map2
    , Checked, isChecked
    , Public, val, val2
    , Internal, internalVal, internalVal2
    , min, max
    , serialize, serializeChecked
    )

{-|

@docs Typed


## who can create


### tagged creation

@docs Tagged, tag, map, map2


### checked creation

@docs Checked, isChecked


## who can access


### public access

@docs Public, val, val2


### internal access

@docs Internal, internalVal, internalVal2


## compare

@docs min, max


## transform

@docs serialize, serializeChecked

-}

import Serialize


{-| A value is wrapped in the `type Typed` with a phantom `tag`.

A `Typed ... Meters ... Float` can't be called a `Typed ... Kilos ... Float` anymore!

For `type`s with just 1 constructor with a value a `Typed` can be a good replacement.


### who can construct such a value

  - [`Checked`](#Checked)
  - [`Tagged`](#Tagged)


### who can access the value

  - [`Public`](#Public)
  - [`Internal`](#Internal)

all promise additional type-safety.


### reading types

    map :
        (value -> mappedValue)
        -> Typed whoCanCreate_ tag whoCanAccess value
        -> Typed Tagged tag whoCanAccess mappedValue

Is saying:

  - it works on every `Typed`
  - it returns a value that is [`Tagged`](#Tagged), not [`Checked`](#Checked)
  - if the input is [`Public`](#Public) or [`Internal`](#Internal), the result will be the same

Note: Calling **`(==)` on `Typed`s causes elm to crash**.
This prevents users from finding out the inner value without using `val` or `internalVal` functions.

-}
type Typed whoCanCreate tag whoCanAccess value
    = Typed (() -> value)


{-| Only the ones with access to the `tag` constructor can access the `internalVal`.

Meaning that access can be limited to

  - inside a module

```
module Special exposing (Special)

type alias Special =
    Typed Tagged SpecialTag Internal SpecialValue
```

  - inside a package (only with [`Checked`](#Checked))

        Internal exposing (Tag(..))
        A exposing (A)
            import Internal exposing (Tag(..))
        B exposing (B)
            import Internal exposing (Tag(..))

    ```json
    'exposed-modules' : [ "A", "B" ]
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

Example `... Checked ... NaturalNumberTag Int`

→ **✓** not every `Int` can be called a `NaturalNumber`, it must be checked!

-}
type Checked
    = Checked Never



--


{-| Create a new [`Tagged`](#Tagged) value.

  - can be [`Checked`](#Checked) with [`isChecked`](#isChecked)
  - becomes [`Internal`](#Internal)/[`Public`](#Public) when annotated that way

Modifying won't change the type.

-}
tag : value -> Typed Tagged tag_ whoCanAccess_ value
tag value =
    (\() -> value) |> Typed



-- ## access


{-| Read the value inside a [`Public`](#Public) `Typed`.
-}
val : Typed tag_ whoCanCreate_ Public value -> value
val =
    \(Typed value) -> value ()


{-| Use the values of 2 [`Public`](#Public) `Typed`s to return a result.

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

Note: Calling **`(==)` on `Typed`s causes elm to crash**.
This prevents users from finding out the inner value without using `val` or `internalVal` functions.

-}
val2 :
    (aValue -> bValue -> resultValue)
    -> Typed aTag_ whoCanCreateA_ Public aValue
    -> Typed bTag_ whoCanCreateB_ Public bValue
    -> resultValue
val2 binOp aTyped bTyped =
    binOp (val aTyped) (val bTyped)


{-| After calling `tag` or modifying a checked value, you get a [`Tagged`](#Tagged). To tell the type that the result value is [`Checked`](#Checked), use `isChecked tag`.

The type of `tag` might even change in that operation.

    oddPlusOdd : Odd -> Odd -> Even
    oddPlusOdd oddToAdd =
        Typed.map2 (+) oddToAdd
            >> isChecked Even

-}
isChecked :
    checkedTag
    -> Typed whoCanCreate_ tag_ whoCanAccess value
    -> Typed Checked checkedTag whoCanAccess value
isChecked _ =
    \(Typed value) -> value |> Typed



-- ## no need to check


{-| Alter the value inside.

If the `Typed` was a [`Checked`](#Checked), it becomes a [`Tagged`](#Tagged).

    type alias Meters =
        Typed Tagged MetersTag Public Int

    go1km : Meters -> Meters
    go1km =
        Typed.map ((+) 1000)

-}
map :
    (value -> mappedValue)
    -> Typed whoCanCreate_ tag whoCanAccess value
    -> Typed Tagged tag whoCanAccess mappedValue
map alter =
    \(Typed value) -> value >> alter |> Typed


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
    (aValue -> bValue -> combinedValue)
    -> Typed whoCanCreateA_ tag whoCanAccess aValue
    -> Typed whoCanCreateB_ tag whoCanAccess bValue
    -> Typed Tagged tag whoCanAccess combinedValue
map2 binOp aTyped bTyped =
    let
        (Typed aValue) =
            aTyped

        (Typed bValue) =
            bTyped
    in
    (\() -> binOp (aValue ()) (bValue ())) |> Typed


{-| If you have an [`Internal`](#Internal) value, its value can't be read by users.

However, if you have the `tag` constructor, you can access this value.

    type alias OptimizedList a =
        Typed
            Checked
            OptimizedListTag
            Internal
            { list : List a, length : Int }

    type OptimizedListTag
        = OptimizedList

    toList =
        internalVal OptimizedList >> .list

-}
internalVal :
    tag
    -> Typed whoCanCreate_ tag whoCanAccess_ value
    -> value
internalVal _ =
    \(Typed value) -> value ()


{-| Take 2 [`Internal`](#Internal) values with the same tag and combine them.

    type alias OptimizedList a =
        Typed
            Checked
            OptimizedListTag
            Internal
            { list : List a, length : Int }

    type OptimizedListTag
        = OptimizedList

    equal a b =
        internalVal2 (==) OptimizedList a b

Note: Calling **`(==)` on `Typed`s causes elm to crash**.
This prevents users from finding out the inner value without using `val` or `internalVal` functions.

-}
internalVal2 :
    (aValue -> bValue -> combinedValue)
    -> tag
    -> Typed whoCanCreateA_ tag whoCanAccessA_ aValue
    -> Typed whoCanCreateB_ tag whoCanAccessB_ bValue
    -> combinedValue
internalVal2 binOp tag_ aTyped bTyped =
    binOp (internalVal tag_ aTyped) (internalVal tag_ bTyped)



-- ## compare


{-| The greater of 2 `Typed` `comparable` [`Typed`](#Typed) values.

    Typed.max three four
    --> four

-}
max :
    Typed whoCanCreate tag whoCanAccess comparable
    -> Typed whoCanCreate tag whoCanAccess comparable
    -> Typed whoCanCreate tag whoCanAccess comparable
max a b =
    let
        (Typed aValue) =
            a

        (Typed bValue) =
            b
    in
    (\() -> Basics.max (aValue ()) (bValue ())) |> Typed


{-| The smaller of 2 `Typed` `comparable` [`Typed`](#Typed) values.

    Typed.min three four
    --> three

-}
min :
    Typed whoCanCreate tag whoCanAccess comparable
    -> Typed whoCanCreate tag whoCanAccess comparable
    -> Typed whoCanCreate tag whoCanAccess comparable
min a b =
    let
        (Typed aValue) =
            a

        (Typed bValue) =
            b
    in
    (\() -> Basics.min (aValue ()) (bValue ())) |> Typed



-- ## serialize


{-| A [`Codec`](https://package.elm-lang.org/packages/MartinSStewart/elm-serialize/latest/)
to serialize [`Tagged`](#Tagged) [`Public`](#Public) [`Typed`](#Typed) values.
-}
serialize :
    Serialize.Codec error value
    -> Serialize.Codec error (Typed Tagged tag_ Public value)
serialize serializeValue =
    serializeValue
        |> Serialize.map tag val


{-| A [`Codec`](https://package.elm-lang.org/packages/MartinSStewart/elm-serialize/latest/) to serialize [`Typed`](#Typed) values.

We don't trust that the values we encode still have the same promises as our [`Checked`](#Checked) values.

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
                identity

    module EfficientList exposing (serialize)

    type EfficientListTag
        = EfficientList

    type alias EfficientList =
        Typed Checked EfficientListTag
            Internal { list : List a, length : Int }

    serialize =
        Typed.serializeChecked EfficientList
            (\list ->
                { list = list
                , length = List.length length
                }
                    |> Ok
            )
            .list
            Serialize.list

-}
serializeChecked :
    tag
    -> (value -> Result error checkedValue)
    -> (checkedValue -> value)
    -> Serialize.Codec error value
    ->
        Serialize.Codec
            error
            (Typed Checked tag whoCanAccess_ checkedValue)
serializeChecked tag_ checkValue toValue serializeValue =
    serializeValue
        |> Serialize.mapValid
            (checkValue >> Result.map (tag >> isChecked tag_))
            (internalVal tag_ >> toValue)
