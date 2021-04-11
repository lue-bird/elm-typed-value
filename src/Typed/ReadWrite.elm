module Typed.ReadWrite exposing
    ( ReadWrite, tag
    , readOnly, writeOnly
    )

{-|

@docs ReadWrite, tag


## restrict

@docs readOnly, writeOnly

-}

import Internal exposing (Allowed, NotAllowed, ReadOnly, Typed(..), WriteOnly)


{-| Allows accessing the value, creating & updating instances.
-}
type alias ReadWrite tag value =
    Typed tag value { write : NotAllowed, read : Allowed }


{-| Create a new tagged value that you can read & update.
-}
tag : value -> ReadWrite tag value
tag value_ =
    Typed value_


{-| The first argument, the `tag` verifies that you are in the module that is allowed to create a `ReadOnly`.
-}
readOnly : tag -> ReadWrite tag value -> ReadOnly tag value
readOnly _ =
    \(Typed value) -> Typed value


{-| -}
writeOnly : ReadWrite tag value -> WriteOnly tag value
writeOnly =
    \(Typed value) -> Typed value
