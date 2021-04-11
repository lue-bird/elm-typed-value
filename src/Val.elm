module Val exposing
    ( Val
    , ReadWrite, tag
    , untag, untag2
    , ReadOnly, readOnly, write
    , map, map2, andThen
    , WriteOnly, writeOnly
    , Readable, Writable
    )

{-|

@docs Val

@docs ReadWrite, tag


## read

@docs Read


### scan

@docs untag, untag2


### read-only

@docs ReadOnly, readOnly, write


## write

@docs Write


### modify

@docs map, map2, andThen


### write-only

@docs WriteOnly, writeOnly

-}


{-| value typed `Val` value.

You can control data modifiability by giving permission to the type variable `permission`.

-}
type Val tag value readWrite
    = Val value


type Allowed
    = Yes Never


type NotAllowed
    = No Never



-- Permissions


{-| Be able to access the value & create new instances.
-}
type alias ReadWrite =
    { write : NotAllowed, read : Allowed }


{-| `ReadOnly` prohibits users to call all functions that construct or update like `map` & `andThen`.
-}
type alias ReadOnly =
    { read : Allowed, write : NotAllowed }


{-| A `WriteOnly` `Val` prohibits using its value.


    type alias User =
        { password : WriteOnly Password String

        --...
        }

    showUsYourPassword user =
        user.password |> Val.value

    --> compile-time error

The only thing you can still use is `==` on 2 `WriteOnly`s of the same type.

-}
type alias WriteOnly =
    { write : Allowed, read : NotAllowed }



-- Policies


{-| Allow accessing its value.
-}
type alias Readable write =
    { write | read : Allowed }


{-| Allow updating creating new instances or.
-}
type alias Writable read =
    { read | write : Allowed }



-- create


tag : value -> Val tag value ReadWrite
tag value_ =
    Val value_



-- restrict


{-| The first argument, the `tag` verifies that you are in the module that is allowed to create a `ReadOnly` `Val`.
-}
readOnly : tag -> Val tag value ReadWrite -> Val tag value ReadOnly
readOnly _ =
    untag >> Val


{-| -}
writeOnly : Val tag value ReadWrite -> Val tag value WriteOnly
writeOnly =
    untag >> Val


{-| The first argument, the `tag` verifies that you are in the module that is allowed to modify a `ReadOnly` `Val`.
-}
write : tag -> Val tag value ReadOnly -> Val tag value ReadWrite
write tag_ =
    untag >> tag >> readOnly tag_



-- scan


{-| Read the value inside the `Val`.
-}
untag : Val tag value (Readable write) -> value
untag =
    \(Val value_) -> value_


{-| Use the values of 2 readable `Val`s to return a result.

    type alias PrimeNumber =
        Val PrimeNumberTag Int ReadOnly

    prime3 : PrimeNumber
    prime3 =
        Val.readOnly PrimeNumber (Val.new 3)

    prime5 =
        Val.readOnly PrimeNumber (Val.new 5)

In another module

    Val.values2 prime3 prime5
    --> 8

In another module

    type alias NonPrime =
        {- ... -}
        ReadOnly

    fromMultiplyingPrimes aPrime bPrime =
        Val.values2 aPrime bPrime
            |> Val.new
            |> Val.readOnly NonPrime

-}
untag2 :
    (aValue -> bValue -> resultValue)
    -> Val aTag aValue (Readable aWrite)
    -> Val bTag bValue (Readable bWrite)
    -> resultValue
untag2 binOp aVal bVal =
    binOp (untag aVal) (untag bVal)



-- modify


{-| Alter the value inside.

    type alias Meters =
        Val MetersTag Int ReadWrite

    type alias Millimeters =
        Val MilliMetersTag ReadWrite

    metersToMillimeters : Meters -> Millimeters
    metersToMillimeters meters =
        meters |> Val.map ((*) 1000)

-}
map :
    (value -> mappedValue)
    -> Val tag value (Writable read)
    -> Val resultTag mappedValue (Writable read)
map alter =
    andThen (alter >> Val)


{-| Use the values of 2 readable `Val`s to return a result.

    type alias PrimeNumber =
        Val PrimeNumberTag Int ReadOnly

    prime3 : PrimeNumber
    prime3 =
        Val.readOnly PrimeNumber (Val.new 3)

    prime5 =
        Val.readOnly PrimeNumber (Val.new 5)

In another module

    Val.values2 prime3 prime5
    --> 8

In another module

    type alias NonPrime =
        Val NonPrimeTag Int ReadOnly

    fromMultiplyingPrimes aPrime bPrime =
        Val.values2 aPrime bPrime
            |> Val.new
            |> Val.readOnly NonPrime

-}
map2 :
    (aValue -> bValue -> resultValue)
    -> Val aTag aValue (Readable aWrite)
    -> Val bTag bValue (Readable bWrite)
    -> Val resultTag resultValue ReadWrite
map2 binOp aVal bVal =
    untag2 binOp aVal bVal
        |> tag


{-| -}
andThen :
    (value -> Val resultTag resultValue resultPermission)
    -> Val tag value (Writable read)
    -> Val resultTag resultValue resultPermission
andThen f =
    \(Val value_) -> f value_
