module Internal exposing (Allowed, NotAllowed, ReadOnly, ReadWrite, Typed(..), WriteOnly)


type Typed tag value readWrite
    = Typed value


type Allowed
    = Allowed Never


type NotAllowed
    = NotAllowed Never


type alias ReadOnly tag value =
    Typed tag value { read : Allowed, write : NotAllowed }


type alias WriteOnly tag value =
    Typed tag value { write : Allowed, read : NotAllowed }


type alias ReadWrite tag value =
    Typed tag value { write : NotAllowed, read : Allowed }
