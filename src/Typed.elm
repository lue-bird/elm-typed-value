module Typed exposing
    ( Typed, new
    , ReadWrite
    , Readable
    , value, values2
    , ReadOnly, is
    , Writable
    , map, map2
    , WriteOnly, writeOnly
    )

{-|

@docs Typed, new

Both `Readable` & `Writable`:

@docs ReadWrite


## read

@docs Readable

@docs value, values2


### read-only

@docs ReadOnly, is


## write

@docs Writable

@docs map, map2


### write-only

@docs WriteOnly, writeOnly

-}


{-| A value is wrapped in a `type` with a phantom `tag`,
so that a `Typed A Int ...` is not a `Typed B Int ...`.

There are 3 wrappers of type `Typed`

  - [`ReadOnly`](Typed#ReadOnly):
      - only its value can be read everywhere
      - creating new ones & updating is only possible inside the module
  - [`WriteOnly`](Typed#WriteOnly):
      - can be updated everywhere
      - its value can never be read
  - [`ReadWrite`](Typed#ReadWrite):
      - you can both access the value & create new ones

→ additional type-safety.

You will mostly see the type `Typed` as a function argument type.

    map :
        (value -> value)
        -> Typed tag value { read | write : write }
        -> Writable tag value read

Is saying: Works for every `Typed`.
The result is `Writable` and has the same `read` permission.

-}
type Typed tag value readWritePermissions
    = Typed value


{-| Create a new tagged value that can be `ReadOnly`. If you start modifying that value, it becomes a `ReadWrite`.
-}
new : tag -> value -> Readable tag value write
new _ value_ =
    Typed value_


type Allowed
    = Allowed Never


type NotAllowed
    = NotAllowed Never


{-| Allows accessing the value, creating & updating instances.
-}
type alias ReadWrite tag value =
    Typed tag value { write : Allowed, read : Allowed }



-- ## read


{-| Accessing its value is allowed.
-}
type alias Readable tag value write =
    Typed tag value { write | read : Allowed }


{-| Creating or updating instances isn't allowed.
-}
type alias ReadOnly tag value =
    Typed tag value { read : Allowed, write : NotAllowed }


{-| Read the value inside the `Readable`.
-}
value : Readable tag value write -> value
value =
    \(Typed value_) -> value_


{-| Use the values of 2 `Readable`s to return a result.

    type alias PrimeNumber =
        ReadOnly PrimeNumberTag Int

    prime3 : PrimeNumber
    prime3 =
        Typed.new PrimeNumber 3

    prime5 =
        Typed.new PrimeNumber 5

Everywhere

    Typed.values2 (+) prime3 prime5
    --> 8

    Typed.values2 Tuple.pair prime3 prime5
    --> ( 3, 5 )

-}
values2 :
    (aValue -> bValue -> resultValue)
    -> Readable aTag aValue aWrite
    -> Readable bTag bValue bWrite
    -> resultValue
values2 binOp aTyped bTyped =
    binOp (value aTyped) (value bTyped)


{-| After you modified a `ReadOnly`, it becomes a `ReadWrite`. To transform it back, use `is tag`.

The `tag` verifies that you are still allowed to create `ReadOnly`s with that `tag`.

The type of tag might even change in that operation.

    type alias Length unit =
        ReadWrite unit Float

    type Meters
        = Meters

    type Millimeters
        = Millimeters

    -- use a type annotation: this should only convert meters
    metersToMillimeters : Length Meters -> Length Millimeters
    metersToMillimeters =
        Typed.map ((*) 1000)
            >> Typed.is Millimeters

-}
is :
    readOnlyTag
    -> Readable tag value write
    -> Readable readOnlyTag value resultWrite
is _ =
    value >> Typed



-- ## write


{-| Allow updating creating new instances or.
-}
type alias Writable tag value read =
    Typed tag value { read | write : Allowed }


{-| Using its value isn't allowed.

    type alias Password =
        WriteOnly PasswordTag String

    type PasswordTag
        = Password Never

    type alias User =
        { password : Password

        --...
        }

    showUsYourPassword user =
        -- compile-time error
        user.password |> Typed.value

The only thing you can still use is `==` on 2 `WriteOnly`s of the same type.

-}
type alias WriteOnly tag value =
    Typed tag value { write : Allowed, read : NotAllowed }


{-| Alter the value inside.

If the `Typed` was a `ReadOnly`, it becomes a `Typed`.

    type alias Meters =
        Typed MetersTag Int Typed

    type alias Millimeters =
        Typed MilliMetersTag Typed

    go1km : Meters -> Meters
    go1km =
        Typed.map ((+) 1000)

-}
map :
    (value -> value)
    -> Typed tag value { read | write : write }
    -> Writable tag value read
map alter =
    \(Typed value_) -> alter value_ |> Typed


{-| Use the values of 2 `Typed`s to return a result.

The result becomes a `Writable` with the same reading permission as the 2 inputs.

    type alias PrimeNumber =
        Typed PrimeNumberTag Int ReadOnly

    prime3 : PrimeNumber
    prime3 =
        readOnly PrimeNumber (tag 3)

    prime5 =
        readOnly PrimeNumber (tag 5)

In another module

    Typed.values2 prime3 prime5
    --> 8

In another module

    type alias NonPrime =
        Typed NonPrimeTag Int ReadOnly

    fromMultiplyingPrimes aPrime bPrime =
        Typed.map2 (*) aPrime bPrime
            |> readOnly NonPrime

-}
map2 :
    (value -> value -> value)
    -> Typed tag value { read | write : aWrite }
    -> Typed tag value { read | write : bWrite }
    -> Writable tag value read
map2 binOp aTyped bTyped =
    let
        (Typed aValue) =
            aTyped

        (Typed bValue) =
            bTyped
    in
    binOp aValue bValue |> Typed


{-| Stop allowing access to the `value`.
-}
writeOnly : Writable tag value read -> WriteOnly tag value
writeOnly =
    \(Typed value_) -> Typed value_
