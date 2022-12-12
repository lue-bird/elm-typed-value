module Typed exposing
    ( Typed
    , Tagged, tag
    , Checked, isChecked
    , Public, untag
    , Internal, internal
    , map, mapToTyped, mapTo, and
    , mapWrap, wrapIsChecked, andWrap
    , mapUnwrap
    )

{-|

@docs Typed


## who can create


### tagging

@docs Tagged, tag


### checking

@docs Checked, isChecked


## who can access


### public access

@docs Public, untag


### internal access

@docs Internal, internal


## transform

@docs map, mapToTyped, mapTo, and


## wrapping

@docs mapWrap, wrapIsChecked, andWrap
@docs mapUnwrap


### [`serialize`](https://package.elm-lang.org/packages/MartinSStewart/elm-serialize/latest/) examples

    module ListOptimized exposing (serialize)

    type ListOptimizedTag
        = ListOptimized

    type alias ListOptimized element =
        Typed
            Checked
            ListOptimizedTag
            Internal
            { list : List element, length : Int }

    fromList =
        \list ->
            { list = list
            , length = length |> List.length
            }
                |> tag ListOptimized

    serialize elementSerialize =
        Serialize.list elementSerialize
            |> Serialize.map
                fromList
                (\listOptimized ->
                    listOptimized
                        |> internal ListOptimized
                        |> .list
                )


#### don't trust decoded values

    module Nat exposing (fromInt, serialize)

    import Serialize
    import Typed exposing (Checked, Internal, Typed, internal, tag)

    type NatTag
        = Nat

    fromInt =
        \int ->
            if int >= 0 then
                Ok (tag Nat int)

            else
                Err "Int was negative, so it couldn't be decoded as a Nat"

    serialize =
        Serialize.int
            |> Serialize.mapValid fromInt (internal Nat)

-}


{-| A value is wrapped in the `type Typed` with a phantom `tag`.

A `Typed ... Meters ... Float` can't be called a `Typed ... Kilos ... Float` anymore!

For `type`s with just 1 constructor with a value a `Typed` can be a good replacement.


### who can construct such a value

  - [`Checked`](#Checked)
  - [`Tagged`](#Tagged)


### who can access the value

  - [`Public`](#Public)
  - [`Internal`](#Internal)


### reading types

    map :
        (value -> valueMapped)
        -> Typed whoCanCreate_ tag whoCanAccess value
        -> Typed Tagged tag whoCanAccess valueMapped

Is saying:

  - works on any `Typed`
  - returns a value that is [`Tagged`](#Tagged), not [`Checked`](#Checked)
  - if the input is [`Public`](#Public) or [`Internal`](#Internal), the result will be the same

Note: Calling `==` is still possible on [`Internal`](#Internal) `Typed`s to allow storing the value in the model, ...

If you really need to prevent users from finding out the inner value without using `untag` or `internal`, try

  - → trick elm to always give `False` when checked for equality:
      - `Typed ... ( value, Unique )` with [`harrysarson/`: `Unique`](https://dark.elm.dmy.fr/packages/harrysarson/elm-hacky-unique/latest/)
  - → cause elm to crash when checked for equality:
      - `Typed ... (() -> value)`
      - `Typed ... ( value, Json.Encode.Value )`
      - `Typed ... ( value, Regex )`
      - ...

-}
type Typed whoCanCreate tag whoCanAccess value
    = Typed tag value


{-| Only devs with access to the tag constructor can access the [`internal`](#internal).

→ access can be limited to

  - inside a module

        module Special exposing (Special)

        type alias Special =
            Typed Tagged SpecialTag Internal SpecialValue

  - inside a package

        Internal exposing (Tag(..))
        A exposing (A)
            import Internal exposing (Tag(..))
        B exposing (B)
            import Internal exposing (Tag(..))

    ```json
    'exposed-modules' : [ "A", "B" ]
    ```

This in combination with [`Checked`](#Checked) helps hiding the internal implementation just like a new `type`.

    import RecordWithoutConstructorFunction exposing (RecordWithoutConstructorFunction)

    type alias ListOptimized element =
        Typed Checked ListOptimizedTag Internal (ListOptimizedInternal element)

    type alias ListOptimizedInternal element =
        RecordWithoutConstructorFunction
            { list : List element, length : Int }

[`RecordWithoutConstructorFunction`](https://dark.elm.dmy.fr/packages/lue-bird/elm-no-record-type-alias-constructor-function/latest/)
tricks elm into not creating a `ListOptimizedInternal` constructor function.

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

→ **✓** not every `Int` can be called a `NumberNatural`, it must be checked!

-}
type Checked
    = Checked Never



--


{-| Create a new [`Tagged`](#Tagged) value.

  - can be [`Checked`](#Checked) with [`isChecked`](#isChecked) or [`mapTo`](#mapTo)
  - becomes [`Internal`](#Internal)/[`Public`](#Public) when annotated that way

Modifying won't change the type.

-}
tag : tag -> value -> Typed checked_ tag whoCanAccess_ value
tag tag_ value =
    value |> Typed tag_



-- ## access


{-| The [`untag`](#untag)ged value inside a [`Public`](#Public) `Typed`.

    module Prime exposing (Prime, n3, n5)

    type alias Prime =
        Typed Checked PrimeTag Public Int

    type PrimeTag
        = Prime

    n3 : Prime
    n3 =
        3 |> tag Prime

    n5 : Prime
    n5 =
        5 |> tag Prime

    -- in another module using Prime

    import Typed exposing (untag)

    ( n3, n5 ) |> Tuple.mapBoth untag untag
    --> ( 3, 5 )

    (n3 |> untag) + (n5 |> untag)
    --> 8

    (n3 |> untag) < (n5 |> untag)
    --> True

-}
untag : Typed tag_ whoCanCreate_ Public value -> value
untag =
    \(Typed _ value) -> value


{-| To confirm that its value should be considered [`Checked`](#Checked), use `isChecked tag`

    module Even exposing (Even, add, multiply)

    import Typed exposing (Checked, Public, Typed)

    type alias Even =
        Typed Checked EvenTag Public Int

    type EvenTag
        = Even

    multiply : Int -> Even -> Even
    multiply factor =
        \even ->
            even
                |> Typed.map (\int -> int * factor)
                |> Typed.isChecked Even

    add : Even -> Even -> Even
    add toAddEven =
        \even ->
            even
                |> Typed.and toAddEven
                |> Typed.map
                    (\( int, toAddInt ) -> int + toAddInt)
                |> Typed.isChecked Even

If the tag would change after [`map`](#map) however, use [`mapTo`](#mapTo)

    oddAddOdd : Odd -> Odd -> Even
    oddAddOdd oddToAdd =
        \odd ->
            odd
                |> Typed.and oddToAdd
                -- ↓ same as mapTo Even (\( o0, o1 ) -> o0 + 01)
                |> Typed.map (\( o0, o1 ) -> o0 + 1)
                |> Typed.isChecked Even

[`mapTo`](#mapTo) is better here since you don't have weird intermediate results like

    odd
        -- : Odd
        |> Typed.and oddToAdd
        |> Typed.map (\( o0, o1 ) -> o0 + 1)
        --: Odd
        |> ...

-}
isChecked :
    tagChecked
    ->
        (Typed whoCanCreate_ tagChecked whoCanAccess_ thing
         -> Typed checked_ tagChecked whoCanAccessChecked_ thing
        )
isChecked tagConfirmation =
    \(Typed _ thing) ->
        thing |> Typed tagConfirmation


{-| [`map`](#map) which allows specifying how the tag changes
while keeping its access and create promises.

    fromMultiplyingPrimes : Prime -> Prime -> NonPrime
    fromMultiplyingPrimes primeA primeB =
        (primeA |> Typed.and primeB)
            |> Typed.mapTo NonPrime (\a b -> a * b)

If the tag stays the same, just [`map`](#map)
and if necessary add an [`isChecked`](#isChecked)

-}
mapTo :
    tagMapped
    -> (value -> valueMapped)
    ->
        (Typed whoCanCreate_ tag_ Public value
         -> Typed whoCanCreateMapped_ tagMapped whoCanAccessMapped_ valueMapped
        )
mapTo mappedTag valueChange =
    \(Typed _ value) ->
        value |> valueChange |> Typed mappedTag


{-| [`map`](#map), then grab the existing tag together with a wrapper tag.

    type alias Hashing subject tag =
        Typed Checked tag Public (subject -> Hash)

    type Each
        = Each

    reverse :
        Hashing element elementHashTag
        -> Hashing (List element) ( Each, elementHashTag )
    reverse elementHashing =
        Typed.mapWrap Each
            (\elementToHash ->
                \list ->
                    list |> List.map elementToHash |> Hash.sequence
            )
            elementHashing

Use [`andWrap`](#andWrap) to map multiple [`Typed`](#Typed)s

This doesn't violate any rules because you have no way of getting to the wrapped tag.

-}
mapWrap :
    mappedTagWrapChecked
    -> (value -> valueMapped)
    ->
        (Typed whoCanCreate_ tag Public value
         -> Typed whoCanCreateMapped_ ( mappedTagWrapChecked, tag ) whoCanAccessMapped_ valueMapped
        )
mapWrap mappedTagWrap valueChange =
    \(Typed tag_ value) ->
        value |> valueChange |> Typed ( mappedTagWrap, tag_ )


{-| Set the contained thing as "[`isChecked`](#isChecked)" by supplying the wrapper tag.
-}
wrapIsChecked :
    tagWrapChecked
    ->
        (Typed whoCanCreate_ ( tagWrapChecked, tag ) whoCanAccess value
         -> Typed checked_ ( tagWrapChecked, tag ) whoCanAccess value
        )
wrapIsChecked mappedTag =
    \(Typed ( _, tag_ ) value) ->
        value |> Typed ( mappedTag, tag_ )


{-| Extract the unwrapped tag from the current tag.

    tag Secret "secret"
        --: Typed Checked Public String
        |> Typed.andWrap (tag Known "known")
        |> Typed.mapUnwrap (\( secret, _ ) -> secret)
        --: Typed Tagged Secret Public String
        |> Typed.untag
    --> "secret"

-}
mapUnwrap :
    (thing -> thingUnwrapped)
    ->
        (Typed whoCanCreate_ ( tagWrap_, tagWrapped ) whoCanAccess thing
         -> Typed Tagged tagWrapped whoCanAccess thingUnwrapped
        )
mapUnwrap thingUnwrap =
    \(Typed ( _, tagWrapped ) value) ->
        value |> thingUnwrap |> Typed tagWrapped


{-| Change the value.

If it was [`Checked`](#Checked) before, it becomes just [`Tagged`](#Tagged).

    import Typed exposing (Public, Tagged, Typed)

    type alias Meters =
        Typed Tagged MetersTag Public Int

    add1km : Meters -> Meters
    add1km =
        Typed.map (\m -> m + 1000)

-}
map :
    (value -> valueMapped)
    ->
        (Typed whoCanCreate_ tag whoCanAccess value
         -> Typed Tagged tag whoCanAccess valueMapped
        )
map valueChange =
    \(Typed tag_ value) ->
        value |> valueChange |> Typed tag_


{-| Use the value to return a `Typed` with the **same tag & access promise**.

    module Home exposing (catOnUnhappyFeed)

    import Cat
    import Typed

    catOnUnhappyFeed : Cat -> Cat
    catOnUnhappyFeed =
        cat
            |> Typed.mapToTyped
                (\catState ->
                    case catState.mood of
                        Unhappy ->
                            cat |> Cat.feed

                        Happy ->
                            cat
                )

using

    module Cat exposing (Cat, feed)

    import Typed

    type alias Cat =
        Typed
            Checked
            CatTag
            Internal
            { mood : Mood, foodReserves : Float }

    feed : Cat -> Cat
    feed =
        Typed.map
            (\cat ->
                { cat | foodReserves = cat.foodReserves + 10 }
            )

Map multiple arguments with [`and`](#and)

-}
mapToTyped :
    (value
     -> Typed whoCanCreateMapped tag whoCanAccess valueMapped
    )
    ->
        (Typed whoCanCreate_ tag whoCanAccess value
         -> Typed whoCanCreateMapped tag whoCanAccess valueMapped
        )
mapToTyped valueMapToTyped =
    \(Typed _ value) ->
        value |> valueMapToTyped


{-|

> You can map, combine, ... even [`Internal`](#Internal) values
> as long as a `Typed` with the **same tag & access promises** are returned in the end


#### into [`map`](#map)

    module Prime exposing (Prime, n3, n5)

    import Typed exposing (Checked, Public, Typed, mapToTyped, tag)

    type alias Prime =
        Typed Checked PrimeTag Public Int

    type PrimeTag
        = Prime

    n3 : Prime
    n3 =
        tag Prime 3

    n5 : Prime
    n5 =
        tag Prime 5

    -- module NonPrime exposing (NonPrime)
    -- import Prime exposing (Prime)
    --
    type alias NonPrime =
        Typed Checked NonPrimeTag Public Int

    type NonPrimeTag
        = NonPrime

    fromMultiplyingPrimes : Prime -> Prime -> NonPrime
    fromMultiplyingPrimes primeA primeB =
        (primeA |> Typed.and primeB)
            |> Typed.mapTo NonPrime (\a b -> a * b)


#### into [`mapToTyped`](#mapToTyped)

    module Typed.Int

    smaller : Typed create tag access Int -> Typed create tag access Int -> Typed create tag access Int
    smaller =
        \int0Typed int1Typed ->
            int0Typed
                |> Typed.and int1Typed
                |> Typed.mapToTyped
                    (\( int0, int1 ) ->
                        if int0 <= int1 then
                            int0Typed
                        else
                            -- int1 < int0
                            int1Typed
                    )

    -- in another module

    type OddTag
        = Odd

    smaller (Typed.tag Odd 3) (Typed.tag Odd 5)
    --> Typed.tag Odd 3

-}
and :
    Typed whoCanCreateFood_ tag whoCanAccess valueFoodLater
    ->
        (Typed whoCanCreate_ tag whoCanAccess valueFoodEarlier
         -> Typed Tagged tag whoCanAccess ( valueFoodEarlier, valueFoodLater )
        )
and typedFoodLater =
    \typedFoodEarlier ->
        let
            (Typed tag_ foodEarlier) =
                typedFoodEarlier

            (Typed _ foodLater) =
                typedFoodLater
        in
        ( foodEarlier, foodLater ) |> tag tag_


{-| [`and`](#and) which keeps the tag from the first [`Typed`](#Typed) in the chain as the wrapping tag.

    type alias Hashing thing tag =
        Typed Checked tag Public thing

    type HashBy
        = HashBy

    hashBy :
        Map mapTag (thing -> thingMapped)
        -> Hashing thingHashingTag thingMapped
        -> Hashing ( HashBy, ( mapTag, thingHashingTag, ) ) thingMapped
    hashBy map mappedHashing =
        map
            |> Typed.andWrap mappedHashing
            |> Typed.mapWrap HashBy
                (\( change, mappedHash ) ->
                    \toHash ->
                        toHash |> change |> mappedHash
                )

-}
andWrap :
    Typed whoCanCreateFood_ tagFood Public valueFoodLater
    ->
        (Typed whoCanCreate_ tagWrap whoCanAccess valueFoodEarlier
         -> Typed Tagged ( tagWrap, tagFood ) whoCanAccess ( valueFoodEarlier, valueFoodLater )
        )
andWrap typedFoodLater =
    \typedFoodEarlier ->
        let
            (Typed tagWrap foodEarlier) =
                typedFoodEarlier

            (Typed tag_ foodLater) =
                typedFoodLater
        in
        ( foodEarlier, foodLater ) |> tag ( tagWrap, tag_ )


{-| If you have an [`Internal`](#Internal) value, its value can't be read by users.

However, if you have access to the `tag` constructor, you can access this value.

    import Typed exposing (Checked, Internal, Typed)

    type alias ListOptimized element =
        Typed
            Checked
            ListOptimizedTag
            Internal
            { list : List (() -> element), length : Int }

    type ListOptimizedTag
        = ListOptimized

    toList =
        \listOptimized ->
            listOptimized
                |> Typed.internal ListOptimized
                |> .list
                |> List.map (\lazy -> lazy ())

    type ListOptimizedTag
        = ListOptimized

    equal =
        let
            listLazyEqual =
                \( listA, listB ) ->
                    case ( listA, listB ) of
                        ( [], _ ) ->
                            False

                        ( _, [] ) ->
                            False

                        ( aHead :: aTail, bHead :: bTail ) ->
                            (aHead () == bTail ())
                                && (( aTail, bTail ) |> listLazyEqual)
        in
        \( listOptimizedA, listOptimizedB ) ->
            let
                a =
                    listOptimizedA |> Typed.internal ListOptimized

                b =
                    listOptimizedB |> Typed.internal ListOptimized
            in
            (a.length == b.length)
                && (( a.list, b.list ) |> listLazyEqual)

Note: this is not all that optimized.

-}
internal :
    tag
    ->
        (Typed whoCanCreate_ tag whoCanAccess_ value
         -> value
        )
internal _ =
    \(Typed _ value) ->
        value
