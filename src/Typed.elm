module Typed exposing
    ( Typed
    , tag
    , Tagged(..), Checked(..), toChecked
    , Public(..), untag, toPublic
    , Internal(..), internal
    , map, mapToTyped, mapTo, and
    , mapToWrap, wrapToChecked
    , wrapToPublic, wrapInternal
    , wrapAnd
    )

{-| Labelled wrapper

@docs Typed


## create

@docs tag


### creator

@docs Tagged, Checked, toChecked


## access


### access public

@docs Public, untag, toPublic


### access internal

@docs Internal, internal


## transform

@docs map, mapToTyped, mapTo, and


## wrapping

A pretty specialized use-case which helps using tags you don't have access to _inside your wrapper tag_

@docs mapToWrap, wrapToChecked
@docs wrapToPublic, wrapInternal
@docs wrapAnd

-}


{-| A tagged thing.

→ A `Typed ... Meters ... Float` isn't accepted as `Typed ... Kilos ... Float` anymore!

For a `type` with just 1 variant, a [`Typed`](#Typed) can be a safe replacement.
It'll save some boilerplate.

A [`Typed`](#Typed) knows

  - who has created it: [`Tagged`](#Tagged) | [`Checked`](#Checked)
  - who can access: [`Public`](#Public) | [`Internal`](#Internal)

More detailed explanations and examples
→ [readme](https://dark.elm.dmy.fr/packages/lue-bird/elm-typed-value/latest/)


### reading types

    map :
        (untyped -> untypedMapped)
        -> Typed creator_ tag accessRight untyped
        -> Typed Tagged tag accessRight untypedMapped

  - works on any [`Typed`](#Typed)
  - we can't be sure that the mapped thing can be considered [`Checked`](#Checked) → [`Tagged`](#Tagged)
  - if the input is [`Public`](#Public) or [`Internal`](#Internal), the result will be the same

Note: Just like with opaque types,
calling `==` is always possible,
even on [`Internal`](#Internal) [`Typed`](#Typed)s
to

  - not lead to accidental crashes
  - enable using it with the debugger
  - allow storing it in a lamdera model/msg
  - ...other stuff like testing becoming easier

If you really need to prevent users from finding out the inner thing without using [`untag`](#untag) or [`internal`](#internal), try

  - → trick elm to always give `False` when checked for equality:
      - `Typed ... ( thing, Unique )` with [`harrysarson/`: `Unique`](https://dark.elm.dmy.fr/packages/harrysarson/elm-hacky-unique/latest/)
  - → cause elm to crash when checked for equality:
      - `Typed ... (() -> thing)`
      - `Typed ... ( thing, Json.Encode.Value )`
      - `Typed ... ( thing, Regex )`
      - ...

-}
type Typed creator tag accessRight untyped
    = Typed tag untyped


{-| Only devs with access to the tag can access the [`internal`](#internal).

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

This in combination with [`Checked`](#Checked) helps hiding the internal implementation just like a new `type`

    import RecordWithoutConstructorFunction exposing (RecordWithoutConstructorFunction)

    type alias ListOptimized element =
        Typed Checked ListOptimizedTag Internal (ListOptimizedInternal element)

    type alias ListOptimizedInternal element =
        RecordWithoutConstructorFunction
            { list : List element, length : Int }

[`RecordWithoutConstructorFunction`](https://dark.elm.dmy.fr/packages/lue-bird/elm-no-record-type-alias-constructor-function/latest/)
tricks elm into not creating a `ListOptimizedInternal` constructor function

-}
type Internal
    = Internal Never


{-| Anyone is able to access the untyped thing
of a [`Typed`](#Typed) `... Public`
by using [`untag`](#untag)
-}
type Public
    = Public Never


{-| Anyone is able to create a [`Typed`](#Typed) `Tagged ...`.

Example `Typed Tagged MetersTag ... Float`
→ _every_ `Float` can be used as a quantity of `Meters`

[`Typed`](#Typed) `Tagged ...` is also the result of trying to [`map`](#map) a [`Checked`](#Checked) thing

    import Typed exposing (Typed, Checked, Public, tag)

    type Prime
        = Prime

    prime3 : Typed Checked Prime Public Int
    prime3 =
        tag Prime 3

    prime3
        |> Typed.map (\prime -> prime + 1) -- tee he
    --: Typed Tagged Prime Public Int

→ any function that only takes `Checked Prime` really only receives the good stuff

-}
type Tagged
    = Tagged Never


{-| Only someone with access to the tag is able to create one of those.

In effect, this means that you can only let "validated" data be of this type.

Example `... Checked ... NaturalNumberTag Int`
→ not every `Int` can be called a `NumberNatural`, it must be [checked](#toChecked)!

-}
type Checked
    = Checked Never



--


{-| Create a new [`Typed`](#Typed) from its raw thing and the tag.
Rights can be chosen by annotating or using it as

  - [`Tagged`](#Tagged)/[`Checked`](#Checked)?
  - [`Internal`](#Internal)/[`Public`](#Public)?

```
passwordSafe =
    tag NowItsSafe "secret1234 th1s iS private oO"

passwordSafe |> Typed.untag
-- "secret1234 th1s iS private oO" oh no!
```

instead

    passwordSafe : Password -- important!
    passwordSafe =
        tag NowItsSafe "secret1234 th1s iS private oO"

    passwordSafe |> Typed.untag
    -- compile-time error

    type alias Password =
        Typed Checked PasswordTag Internal String

    type PasswordTag
        = NowItsSafe

    passwordSafe |> Typed.internal NowItsSafe
    --> "secret1234 th1s iS private oO"
    -- allowed because we could prove we're in the internal module

-}
tag :
    tag
    -> untyped
    -> Typed creatorChecked_ tag accessRightPublic_ untyped
tag tag_ untyped =
    untyped |> Typed tag_



-- ## access


{-| The [`untag`](#untag)ged thing inside a [`Public`](#Public) `Typed`

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
untag : Typed tag_ creator_ Public untyped -> untyped
untag =
    \(Typed _ untyped) -> untyped


{-| If you have an [`Internal`](#Internal) [`Typed`](#Typed),
its untyped thing can't be read by everyone.

If you have access to the tag, you can access its untyped thing

    import Typed exposing (Checked, Internal, Typed)

    type alias ListOptimized element =
        Typed
            Checked
            ListOptimizedTag
            Internal
            -- optimizations might change in the future
            { list : List (() -> element)
            , length : Int
            }

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

[`internal`](#internal) can be seen as
a shortcut for [`toPublic`](#toPublic), then [`untag`](#untag)

    internal tag =
        Typed.toPublic tag >> Typed.untag

-}
internal :
    tag
    ->
        (Typed creator_ tag accessRight_ untyped
         -> untyped
        )
internal tagConfirmation =
    \typed ->
        typed
            |> toPublic tagConfirmation
            |> untag


{-| If you have an [`Internal`](#Internal) [`Typed`](#Typed),
its untyped thing can't be read by everyone.

If you have access to the tag, you can access its untyped thing

    run :
        Typed Checked ( Hashing, thingTag ) Internal (thing -> Hash)
        -> (thing -> Hash)
    run hashing =
        hashing |> Typed.wrapInternal Hashing

[`internal`](#internal) can be seen as
a shortcut for [`wrapToPublic`](#wrapToPublic), then [`untag`](#untag)

    internal tag =
        Typed.wrapToPublic tag >> Typed.untag

-}
wrapInternal :
    tagWrap
    ->
        (Typed creator_ ( tagWrap, tagWrapped_ ) accessRight_ untyped
         -> untyped
        )
wrapInternal tagWrapConfirmation =
    \typed ->
        typed
            |> wrapToPublic tagWrapConfirmation
            |> untag



--


{-| Confirm that it can be considered [`Public`](#Public) by supplying the matching tag.
Now you can annotate or use it as [`Internal`](#Internal)/[`Public`](#Public)

    internal tag =
        toPublic tag >> untag

-}
toPublic :
    tag
    ->
        (Typed creator tag accessRight_ untyped
         -> Typed creator tag accessRightPublic_ untyped
        )
toPublic tagConfirmation =
    \(Typed _ untyped) ->
        untyped |> Typed tagConfirmation


{-| Confirm that it can be considered [`Public`](#Public) by supplying the matching tag.
Now you can annotate or use it as [`Internal`](#Internal)/[`Public`](#Public)

    internal tag =
        toPublic tag >> untag

-}
wrapToPublic :
    tagWrap
    ->
        (Typed creator ( tagWrap, tagWrapped ) accessRight_ untyped
         -> Typed creator ( tagWrap, tagWrapped ) accessRightPublic_ untyped
        )
wrapToPublic tagConfirmation =
    \(Typed ( _, tagWrapped ) untyped) ->
        untyped |> Typed ( tagConfirmation, tagWrapped )



--


{-| Confirm that it can be considered [`Checked`](#Checked) by supplying the matching tag.
Annotate or use it as [`Tagged`](#Tagged)/[`Checked`](#Checked)

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
                |> Typed.toChecked Even

    add : Even -> Even -> Even
    add toAddEven =
        \even ->
            even
                |> Typed.and toAddEven
                |> Typed.map
                    (\( int, toAddInt ) -> int + toAddInt)
                |> Typed.toChecked Even

If the tag would change after [`map`](#map) however, use [`mapTo`](#mapTo)

    oddAddOdd : Odd -> Odd -> Even
    oddAddOdd oddToAdd =
        \odd ->
            odd
                |> Typed.and oddToAdd
                -- ↓ same as mapTo Even (\( o0, o1 ) -> o0 + 01)
                |> Typed.map (\( o0, o1 ) -> o0 + 1)
                |> Typed.toChecked Even

[`mapTo`](#mapTo) is better here since you don't have weird intermediate results like

    odd
        -- : Odd
        |> Typed.and oddToAdd
        |> Typed.map (\( o0, o1 ) -> o0 + 1)
        --: Typed Tagged OddTag Public Int
        |> ...

-}
toChecked :
    tag
    ->
        (Typed creator_ tag accessRight untyped
         -> Typed creatorChecked_ tag accessRight untyped
        )
toChecked tagConfirmation =
    \(Typed _ untyped) ->
        untyped |> Typed tagConfirmation



--


{-| [`map`](#map) which allows specifying a tag for the mapped result.

Rights of the result can be chosen by annotating or using it as

  - [`Tagged`](#Tagged)/[`Checked`](#Checked)
  - [`Internal`](#Internal)/[`Public`](#Public)

```
fromMultiplyingPrimes : Prime -> Prime -> NonPrime
fromMultiplyingPrimes primeA primeB =
    (primeA |> Typed.and primeB)
        |> Typed.mapTo NonPrime (\a b -> a * b)
```

If the tag stays the same, just [`map`](#map)
and if necessary add [`toChecked`](#toChecked)

-}
mapTo :
    mappedTag
    -> (untyped -> mappedUntyped)
    ->
        (Typed creator_ tag_ Public untyped
         -> Typed mappedCreatorChecked_ mappedTag mappedAccessRightPublic_ mappedUntyped
        )
mapTo mappedTag untypedChange =
    \(Typed _ untyped) ->
        untyped |> untypedChange |> Typed mappedTag


{-| [`map`](#map), then put the existing tag after a given wrapper tag

    type alias Hashing subject tag =
        Typed Checked tag Public (subject -> Hash)

    type Each
        = Each

    reverse :
        Hashing element elementHashTag
        -> Hashing (List element) ( Each, elementHashTag )
    reverse elementHashing =
        Typed.mapToWrap Each
            (\elementToHash ->
                \list ->
                    list |> List.map elementToHash |> Hash.sequence
            )
            elementHashing

Use [`wrapAnd`](#wrapAnd) to map multiple [`Typed`](#Typed)s

This doesn't violate any rules because you have no way of getting to the wrapped tag

-}
mapToWrap :
    mappedTagWrap
    -> (untyped -> mappedUntyped)
    ->
        (Typed creator_ tag accessRight untyped
         ->
            Typed
                mappedCreatorChecked_
                ( mappedTagWrap, tag )
                accessRight
                mappedUntyped
        )
mapToWrap mappedTagWrap untypedChange =
    \(Typed tag_ untyped) ->
        untyped |> untypedChange |> Typed ( mappedTagWrap, tag_ )


{-| Allow the creator to be [`Checked`](#Checked) by supplying the wrapper tag

    type Reverse
        = Reverse

    Int.Order.increasing
        |> reverse
        --: Typed Checked ( Reverse, Int.Order.Increasing ) Public ...
        |> Typed.map ...
        --: Typed Tagged ( Reverse, Int.Order.Increasing ) Public ...
        |> Typed.wrapToChecked Reverse
    --: Typed Checked ( Reverse, Int.Order.Increasing ) Public ...

-}
wrapToChecked :
    tagWrap
    ->
        (Typed creator_ ( tagWrap, tag ) accessRight untyped
         -> Typed creatorCheck_ ( tagWrap, tag ) accessRight untyped
        )
wrapToChecked mappedTag =
    \(Typed ( _, tag_ ) untyped) ->
        untyped |> Typed ( mappedTag, tag_ )


{-| Change the untyped thing.

If the creator is [`Checked`](#Checked), it becomes just [`Tagged`](#Tagged)

    import Typed exposing (Public, Tagged, Typed)

    type alias Meters =
        Typed Tagged MetersTag Public Int

    add1km : Meters -> Meters
    add1km =
        Typed.map (\m -> m + 1000)

If you want to confirm that the [`map`](#map)s result is [`Checked`](#Checked), [`toChecked`](#toChecked)

    import Typed exposing (Checked, Public, Typed)

    type alias Odd =
        Typed Checked OddTag Public Int

    type OddTag
        = Odd

    next : Odd -> Odd
    next =
        \odd ->
            odd
                |> Typed.map (\m -> m + 2)
                |> Typed.toChecked Odd

-}
map :
    (untyped -> mappedUntyped)
    ->
        (Typed creator_ tag accessRight untyped
         -> Typed Tagged tag accessRight mappedUntyped
        )
map untypedChange =
    \(Typed tag_ untyped) ->
        untyped |> untypedChange |> Typed tag_


{-| Use the untyped thing to return a [`Typed`](#Typed)
with the **same tag & access rights**

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
    (untyped
     -> Typed creatorMapped tag accessRight mappedUntyped
    )
    ->
        (Typed creator_ tag accessRight untyped
         -> Typed creatorMapped tag accessRight mappedUntyped
        )
mapToTyped untypedMapToTyped =
    \(Typed _ untyped) ->
        untyped |> untypedMapToTyped


{-|

> You can map, combine, ... even [`Internal`](#Internal) [`Typed`](#Typed)s
> as long as a `Typed` with the **same tag & access rights** are returned in the end


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
    Typed nextCreator_ tag accessRight nextUntyped
    ->
        (Typed creator_ tag accessRight untyped
         -> Typed Tagged tag accessRight ( untyped, nextUntyped )
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


{-| [`and`](#and) which keeps the tag from the first [`Typed`](#Typed) in the chain as the wrapping tag

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
            |> Typed.wrapAnd mappedHashing
            |> Typed.mapToWrap HashBy
                (\( change, mappedHash ) ->
                    \toHash ->
                        toHash |> change |> mappedHash
                )

-}
wrapAnd :
    Typed nextCreator_ tagFood Public nextUntyped
    ->
        (Typed creator_ tagWrap accessRight untyped
         -> Typed Tagged ( tagWrap, tagFood ) accessRight ( untyped, nextUntyped )
        )
wrapAnd typedFoodLater =
    \typedFoodEarlier ->
        let
            (Typed tagWrap foodEarlier) =
                typedFoodEarlier

            (Typed tag_ foodLater) =
                typedFoodLater
        in
        ( foodEarlier, foodLater ) |> tag ( tagWrap, tag_ )
