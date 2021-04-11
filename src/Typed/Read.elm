module Typed.Read exposing
    ( Readable
    , value, values2
    , ReadOnly, write
    )

{-|


## read

@docs Readable

@docs value, values2


### read-only

@docs ReadOnly, write

-}

import Internal exposing (Allowed, NotAllowed, ReadWrite, Typed(..))


{-| Accessing its value is allowed.
-}
type alias Readable tag value write =
    Typed tag value { write | read : Allowed }


{-| Creating or updating instances isn't allowed.
-}
type alias ReadOnly tag value =
    Typed tag value { read : Allowed, write : NotAllowed }


{-| Enable writing to a `ReadOnly`. You can use this in the module your tag located.

The first argument, the `tag` verifies that you are in the module that is allowed to modify a `ReadOnly`.

    module DivisibleBy2 exposing (DivisibleBy2, add)

    type alias DivisibleBy2 =
        ReadOnly DivisibleBy2Tag Int

    -- don't expose this
    type DivisibleBy2Tag
        = DivisibleBy2

    add : DivisibleBy2 -> DivisibleBy2 -> DivisibleBy2
    add toAdd =
        Read.write DivisibleBy2
            >> ReadWrite.map2 (+) toAdd

-}
write : tag -> ReadOnly tag value -> ReadWrite tag value
write _ =
    value >> Typed


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
        ReadWrite.readOnly PrimeNumber
            (ReadWrite.tag 3)

    prime5 =
        ReadWrite.readOnly PrimeNumber
            (ReadWrite.tag 5)

Everywhere

    Read.values2 (+) prime3 prime5
    --> 8

    Read.values2 Tuple.pair prime3 prime5
    --> ( 3, 5 )

-}
values2 :
    (aValue -> bValue -> resultValue)
    -> Readable aTag aValue aWrite
    -> Readable bTag bValue bWrite
    -> resultValue
values2 binOp aReadWrite bReadWrite =
    binOp (value aReadWrite) (value bReadWrite)
