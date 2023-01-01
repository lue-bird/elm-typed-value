module Typed exposing
    ( Typed
    , tag
    , Tagged, Checked, toChecked
    , Public, untag, toPublic
    , Internal, internal
    , map, mapToTyped, mapTo, replace
    , and
    , mapToWrap, mapUnwrap
    , wrapToChecked
    , wrapToPublic, wrapInternal
    , wrapAnd
    )

{-| Labelled wrapper

@docs Typed


## create

@docs tag


## creator

@docs Tagged, Checked, toChecked


## access


### access public

@docs Public, untag, toPublic


### access internal

@docs Internal, internal


## transform

@docs map, mapToTyped, mapTo, replace
@docs and


## wrapping

A pretty specialized use-case which helps using tags you don't have access to _inside your wrapper tag_

Examples in the [version 8 announcement](https://github.com/lue-bird/elm-typed-value/blob/master/announcement.md#800)

@docs mapToWrap, mapUnwrap
@docs wrapToChecked
@docs wrapToPublic, wrapInternal
@docs wrapAnd

-}

import Typed.Internal


{-| A tagged thing.

→ A `Typed ... Meters ... Float` isn't accepted as `Typed ... Kilos ... Float` anymore!

For a `type` with just 1 variant, a [`Typed`](#Typed) can be a safe replacement.
It'll save some boilerplate.

A [`Typed`](#Typed) knows

  - who has created it: [`Tagged`](#Tagged) | [`Checked`](#Checked)
  - who can access it: [`Public`](#Public) | [`Internal`](#Internal)

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
type alias Typed creator tag accessRight untyped =
    Typed.Internal.Typed creator tag accessRight untyped


{-| Only those with access to the tag can access the [`internal`](#internal) thing.

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

This in combination with [`Checked`](#Checked)
hides the internals just like an opaque `type`

    type alias ListOptimized element =
        Typed
            Checked
            ListOptimizedTag
            Internal
            { list : List element, length : Int }

    type ListOptimizedTag
        = -- don't expose this variant
          ListOptimizedTag

-}
type alias Internal =
    Typed.Internal.Internal


{-| Anyone is able to access the untyped thing
of a [`Typed`](#Typed) `... Public`
by using [`untag`](#untag)
-}
type alias Public =
    Typed.Internal.Public


{-| Anyone is able to create a [`Typed`](#Typed) `Tagged ...`.

Example: `Typed Tagged MetersTag ... Float`
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
type alias Tagged =
    Typed.Internal.Tagged


{-| Only someone with access to the tag is able to create one of those.

In effect, this means that you can only let "validated" data be of this type.

Example: `... Checked ... NaturalNumberTag Int`
→ not every `Int` can be called a `NumberNatural`, it must be [checked](#toChecked)!

-}
type alias Checked =
    Typed.Internal.Checked



--


{-| Create a new [`Typed`](#Typed) from its raw thing and the tag.
Rights can be chosen by annotating or using it as

  - [`Tagged`](#Tagged)/[`Checked`](#Checked)?
  - [`Internal`](#Internal)/[`Public`](#Public)?

```
passwordSafe =
    tag NowItsSafe "secret1234 th1s iS private oO"

passwordSafe |> Typed.untag
--→ "secret1234 th1s iS private oO" oh no!
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
    Typed.Internal.tag tag_ untyped



-- ## access


{-| The thing inside the [`Typed`](#Typed) [`Public`](#Public)

    -- module Prime exposing (Prime, n3, n5)

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

    (n3 |> untag) < (n5 |> untag)
    --> True

-}
untag : Typed tag_ creator_ Public untyped -> untyped
untag =
    Typed.Internal.untag


{-| Only those who can show the tag
can access the [`Typed`](#Typed) [`Internal`](#Internal):

    import Typed exposing (Checked, Internal, Typed)

    type alias ListOptimized element =
        Typed
            Checked
            ListOptimizedTag
            Internal
            -- optimizations might change in the future
            { list : List element
            , length : Int
            }

    type ListOptimizedTag
        = ListOptimized

    toList =
        \listOptimized ->
            listOptimized
                |> Typed.internal ListOptimized
                |> .list

    type ListOptimizedTag
        = ListOptimized

    equal =
        \( listOptimizedA, listOptimizedB ) ->
            let
                a =
                    listOptimizedA |> Typed.internal ListOptimized

                b =
                    listOptimizedB |> Typed.internal ListOptimized
            in
            if a.length /= b.length then
                False

            else
                a.list == b.list

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


{-| If you have a [`Typed`](#Typed) [`Internal`](#Internal),
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
The result can be annotated or used as [`Internal`](#Internal)/[`Public`](#Public)

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
    \typed ->
        typed |> Typed.Internal.toPublic tagConfirmation


{-| Confirm that it can be considered [`Public`](#Public) by supplying the matching tag.
The result can be annotated or used as [`Internal`](#Internal)/[`Public`](#Public)

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
    \typed ->
        typed |> Typed.Internal.wrapToCheckedPublic tagConfirmation



--


{-| Confirm that it can be considered [`Checked`](#Checked) by supplying the matching tag.
Annotate or use the result as [`Tagged`](#Tagged)/[`Checked`](#Checked)

    -- module Even exposing (Even, add, multiply)


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

If the tag should change after [`map`](#map), [`mapTo`](#mapTo)

    oddAddOdd : Odd -> Odd -> Even
    oddAddOdd oddToAdd =
        \odd ->
            odd
                |> Typed.and oddToAdd
                -- ↓ same as mapTo Even (\( o0, o1 ) -> o0 + 01)
                |> Typed.map (\( o0, o1 ) -> o0 + o1)
                |> Typed.toChecked Even

[`mapTo`](#mapTo) is better here since you don't have weird intermediate results like

    odd
        -- : Odd
        |> Typed.and oddToAdd
        |> Typed.map (\( o0, o1 ) -> o0 + o1)
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
    \typed ->
        typed
            |> internal tagConfirmation
            |> tag tagConfirmation



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
    \typed ->
        typed
            |> untag
            |> untypedChange
            |> tag mappedTag


{-| Swap out its untyped thing for a given replacement.
The tag will stay the same but as with [`map`](#map), the creator will be set to [`Tagged`](#Tagged).

Prefer over [`map`](#map) if you need to allow the result to be [`Public`](#Public)

    type SecretTag
        = Shhh

    secret : Typed Checked SecretTag Internal String
    secret =
        Typed.tag Shhh "dear diary"

    encrypt :
        Typed Checked SecretTag Internal String
        -> Typed Checked SecretTag Internal String

    secret
        |> Typed.replace "since I can't read the secret here, we can make it Public"
        --: Typed Tagged SecretTag Public String
        |> Typed.untag
    --> "since I can't read the secret here, we can make it Public"

Also useful if you want to keep a tag for a different type:

    type alias Vault secretTag =
        Typed Tagged secretTag Internal { encrypted : ( String, List String ) }

    for
        ( Typed Checked tag Internal String
        , List (Typed Checked tag Internal String)
        )
        -> (Vault tag
           -> Vault tag
           )
    for ( secretOne, secretOthers ) =
        \vault ->
            secretOne
                |> Typed.replace
                    { encrypted =
                        ( secretOne |> encrypt, secretOthers |> List.map encrypt )
                    }

-}
replace :
    untypedReplacement
    ->
        (Typed creator_ tag accessRight_ untyped_
         -> Typed Tagged tag accessRightPublic_ untypedReplacement
        )
replace untypedReplacement =
    \typed -> typed |> Typed.Internal.replace untypedReplacement


{-| [`map`](#map), then put the existing tag after a given wrapper tag

    type alias Hashing subject tag =
        Typed Checked tag Public (subject -> Hash)

    type Each
        = Each

    each :
        Hashing element elementHashTag
        -> Hashing (List element) ( Each, elementHashTag )
    each elementHashing =
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
        (Typed creator_ tag Public untyped
         ->
            Typed
                mappedCreatorChecked_
                ( mappedTagWrap, tag )
                mappedAccessRightPublic_
                mappedUntyped
        )
mapToWrap mappedTagWrap untypedChange =
    \typed ->
        tag mappedTagWrap ()
            |> wrapAnd typed
            |> map
                (\( (), wrappedUntyped ) ->
                    wrappedUntyped |> untypedChange
                )
            |> wrapToChecked mappedTagWrap
            |> wrapToPublic mappedTagWrap


{-| Change its untyped thing and adapt the inner, wrapped tag

The result has the same access right as before but is [`Tagged`](#Tagged)
since we haven't verified the changed thing

    -- module Secret exposing (SecretTag, secret)

    type SecretTag
        = Secret

    secret :
        Typed creator_ kind Public a
        -> Typed Checked ( SecretTag, kind ) Internal a
    secret =
        Typed.mapToWrap Secret

    encrypt :
        Typed Checked ( SecretTag, kind ) Internal String
        -> Typed Checked kind Internal { encrypted : String }
    encrypt =
        Typed.mapUnwrap ...

    -- for example in another module

    type DiaryTag
        = Diary

    diary : Typed Checked DiaryTag Internal { encrypted : String }
    diary =
        secret (Typed.tag Diary "dear diary")
            --: Typed Checked ( SecretTag, DiaryTag ) Internal String
            |> Secret.encrypt

Use [`mapToWrap`](#mapToWrap) to wrap the unwrapped thing again with a different tag

-}
mapUnwrap :
    (untyped -> mappedUntyped)
    -> Typed creator_ ( tagWrap_, tagWrapped ) accessRight untyped
    -> Typed Tagged tagWrapped accessRight mappedUntyped
mapUnwrap untypedMap =
    \typed ->
        typed
            |> map untypedMap
            |> Typed.Internal.unwrap


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
        (Typed creator_ ( tagWrap, tagWrapped ) accessRight untyped
         -> Typed creatorChecked_ ( tagWrap, tagWrapped ) accessRight untyped
        )
wrapToChecked tagWrapConfirmation =
    \typed ->
        typed |> Typed.Internal.wrapToCheckedPublic tagWrapConfirmation


{-| Change the untyped thing.

The result is not [`Checked`](#Checked),
so it becomes just [`Tagged`](#Tagged)

    import Typed exposing (Public, Tagged, Typed)

    type alias Meters =
        Typed Tagged MetersTag Public Int

    add1km : Meters -> Meters
    add1km =
        Typed.map (\m -> m + 1000)

To confirm that the [`map`](#map)s result is [`Checked`](#Checked)
→ [`toChecked`](#toChecked)

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
    \typed ->
        typed
            |> mapToTyped
                (\untyped ->
                    typed |> replace (untyped |> untypedChange)
                )


{-| Use the untyped thing to return a [`Typed`](#Typed)
with the **same tag & access right**

    -- module Cat exposing (Cat, feed)
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

    -- in another module
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
    \typed ->
        typed |> Typed.Internal.mapToTyped untypedMapToTyped


{-|

> You can map, combine, ... even [`Internal`](#Internal) [`Typed`](#Typed)s
> as long as a `Typed` with the **same tag & access rights** are returned in the end


#### into [`map`](#map)

    -- module Prime exposing (Prime, n3, n5)


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
    type alias NonPrime =
        Typed Checked NonPrimeTag Public Int

    type NonPrimeTag
        = NonPrime

    fromMultiplyingPrimes : Prime -> Prime -> NonPrime
    fromMultiplyingPrimes primeA primeB =
        (primeA |> Typed.and primeB)
            |> Typed.mapTo NonPrime (\a b -> a * b)


#### into [`mapToTyped`](#mapToTyped)

    -- module Typed.Int

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
        typedFoodEarlier |> Typed.Internal.and typedFoodLater


{-| [`and`](#and) which keeps the tag from the first [`Typed`](#Typed) in the chain as the wrapping tag

    type alias Hashing thing tag =
        Typed Checked tag Public thing

    type HashBy
        = HashBy

    hashBy :
        Map mapTag (thing -> thingMapped)
        -> Hashing thingHashingTag thingMapped
        -> Hashing ( HashBy, ( mapTag, thingHashingTag ) ) thingMapped
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
    \typed ->
        typed |> Typed.Internal.wrapAnd typedFoodLater
