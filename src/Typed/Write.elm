module Typed.Write exposing
    ( Writable
    , map, map2
    , WriteOnly
    )

{-|


## write

Can be modified.

@docs Writable

@docs map, map2

@docs WriteOnly

-}

import Internal exposing (Allowed, NotAllowed, ReadWrite, Typed(..))


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
        user.password |> ReadWrite.value

    --> compile-time error

The only thing you can still use is `==` on 2 `WriteOnly`s of the same type.

-}
type alias WriteOnly tag value =
    Typed tag value { write : Allowed, read : NotAllowed }


{-| Alter the value inside.

    type alias Meters =
        ReadWrite MetersTag Int ReadWrite

    type alias Millimeters =
        ReadWrite MilliMetersTag ReadWrite

    go1km : Meters -> Meters
    go1km =
        Write.map ((+) 1000)

-}
map :
    (value -> value)
    -> Writable tag value read
    -> Writable tag value read
map alter =
    \(Typed value) -> alter value |> Typed


{-| Use the values of 2 readable `ReadWrite`s to return a result.

    type alias PrimeNumber =
        ReadWrite PrimeNumberTag Int ReadOnly

    prime3 : PrimeNumber
    prime3 =
        ReadWrite.readOnly PrimeNumber (ReadWrite.tag 3)

    prime5 =
        ReadWrite.readOnly PrimeNumber (ReadWrite.tag 5)

In another module

    ReadWrite.values2 prime3 prime5
    --> 8

In another module

    type alias NonPrime =
        ReadWrite NonPrimeTag Int ReadOnly

    fromMultiplyingPrimes aPrime bPrime =
        ReadWrite.values2 aPrime bPrime
            |> ReadWrite.tag
            |> ReadWrite.readOnly NonPrime

-}
map2 :
    (value -> value -> value)
    -> Writable tag value write
    -> Writable tag value write
    -> Writable tag value write
map2 binOp aTyped bTyped =
    let
        (Typed aValue) =
            aTyped

        (Typed bValue) =
            bTyped
    in
    binOp aValue bValue |> Typed
