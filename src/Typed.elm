module Typed exposing
    ( Typed
    , Tagged, tag
    , Checked, isChecked
    , Public, untag
    , Internal, internal
    , map, and, mapToTyped
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

@docs map, and, mapToTyped


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

  - can be [`Checked`](#Checked) with [`isChecked`](#isChecked)
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

    n3 =
        3 |> tag Prime

    n5 =
        5 |> tag Prime

in another `module`

    import Tuple.Extra as Tuple
    import Typed exposing (untag)

    ( Prime.n3, Prime.n5 ) |> Tuple.map untag
    --> ( 3, 5 )

    (Prime.n3 |> untag) + (Prime.n5 |> untag)
    --> 8

    (Prime.n3 |> untag) < (Prime.n5 |> untag)
    --> True

-}
untag : Typed tag_ whoCanCreate_ Public value -> value
untag =
    \(Typed _ value) -> value


{-| [Map](#map)ping a [`Checked`](#Checked) value only results in a [`Tagged`](#Tagged) value.

To confirm that the result is [`Checked`](#Checked), use `isChecked tag`.

The type of `tag` can change in that operation.

    import Typed exposing (isChecked, mapToTyped)

    oddAddOdd : Odd -> Odd -> Even
    oddAddOdd oddToAdd =
        \odd ->
            (\o0 o1 -> o1 + o2)
                |> Typed.mapEat odd
                |> mapToTyped (Typed.mapEat oddToAdd)
                |> isChecked Even

-}
isChecked :
    tag
    -> Typed whoCanCreate_ tag_ whoCanAccess value
    -> Typed checked_ tag whoCanAccess value
isChecked tagConfirmation =
    \(Typed _ value) ->
        value |> Typed tagConfirmation


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
    -> Typed whoCanCreate_ tag whoCanAccess value
    -> Typed Tagged tag whoCanAccess valueMapped
map valueChange =
    \(Typed tag_ value) ->
        value |> valueChange |> Typed tag_


{-| Use the value to return a `Typed` with the **same tag & access promise**.

    module Cat exposing (feed)

    import Typed exposing (mapToTyped)

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

in another `module`

    module Home exposing (feedIfUnhappy)

    import Typed exposing (mapToTyped)
    import Cat

    feedIfUnhappy : Cat -> Cat
    feedIfUnhappy =
        cat
            |> mapToTyped
                (\cat ->
                    case cat.mood of
                        Unhappy ->
                            cat |> Cat.feed

                        Happy ->
                            cat
                )

    🐱 |> meet 🐦 --> { 🐱, 🍗 }

Feed multiple arguments with [`and`](#and)

-}
mapToTyped :
    (value
     -> Typed whoCanCreateMapped tag whoCanAccess valueMapped
    )
    -> Typed whoCanCreate_ tag whoCanAccess value
    -> Typed whoCanCreateMapped tag whoCanAccess valueMapped
mapToTyped valueMapToTyped =
    \(Typed _ value) ->
        value |> valueMapToTyped


{-|

> You can map, combine, ... even [`Internal`](#Internal) values
> as long as a `Typed` with the **same tag & access promises** are returned in the end


#### feed [`map`](#map)

    module Prime exposing (Prime, n3, n5)

    import Typed exposing (Checked, Public, Typed, isChecked, mapToTyped)

    type alias Prime =
        Typed Checked PrimeTag Public Int

    n3 =
        tag 3 |> isChecked Prime

    n5 =
        tag 5 |> isChecked Prime


    module NonPrime exposing (NonPrime)

    import Prime exposing (Prime)

    type alias NonPrime =
        Typed Checked NonPrimeTag Public Int

    fromMultiplyingPrimes : Prime -> Prime -> NonPrime
    fromMultiplyingPrimes primeA primeB =
        (primeA |> Typed.and primeB)
            |> Typed.map (\a b -> a * b)
            |> isChecked NonPrime


#### feed [`mapToTyped`](#mapToTyped)

    min :
        Typed whoCanCreate tag whoCanAccess Int
        -> Typed whoCanCreate tag whoCanAccess Int
        -> Typed whoCanCreate tag whoCanAccess Int
    min =
        \comparable0 comparable1 ->
            comparable0
                |> Typed.and comparable1
                |> Typed.mapToTyped
                    (\( c0, c1 ) ->
                        if c0 < c1 then
                            comparable1

                        else
                            comparable0
                    )

-}
and :
    Typed whoCanCreateFood_ tag whoCanAccess valueFoodLater
    -> Typed whoCanCreate_ tag whoCanAccess valueFoodEarlier
    -> Typed Tagged tag whoCanAccess ( valueFoodEarlier, valueFoodLater )
and typedFoodLater =
    \typedFoodEarlier ->
        let
            (Typed tag_ foodEarlier) =
                typedFoodEarlier

            (Typed _ foodLater) =
                typedFoodLater
        in
        ( foodEarlier, foodLater ) |> tag tag_


{-| If you have an [`Internal`](#Internal) value, its value can't be read by users.

However, if you have access to the `tag` constructor, you can access this value.

    import Typed exposing (Checked, Internal, Typed, internal)

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
                |> internal ListOptimized
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
                    listOptimizedA |> internal ListOptimized

                b =
                    listOptimizedB |> internal ListOptimized
            in
            (a.length == b.length)
                && (( a.list, b.list ) |> listLazyEqual)

Note: this is not all that optimized.

-}
internal :
    tag
    -> Typed whoCanCreate_ tag whoCanAccess_ value
    -> value
internal _ =
    \(Typed _ value) ->
        value
