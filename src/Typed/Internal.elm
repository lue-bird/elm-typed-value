module Typed.Internal exposing
    ( Typed
    , Tagged(..), Checked(..), Public(..), Internal(..)
    , tag
    , wrapToCheckedPublic
    , toPublic, untag
    , mapToTyped, replace, unwrap
    , and, wrapAnd
    )

{-| Labelled wrapper.


## Why would we want an `.Internal module`?

Some functions in the package exposed `Typed` are built using other primitives.
These are exposed just for convenience
and shouldn't be allowed to directly use the `Typed` variant.

Only allowing unsafe operations here helps keeping things safe and clean.
The goal is as always to trim the size of this `module` as much as possible.

@docs Typed
@docs Tagged, Checked, Public, Internal


## create

@docs tag


## rights

@docs wrapToCheckedPublic


## access

@docs toPublic, untag


## transform

@docs mapToTyped, replace, unwrap
@docs and, wrapAnd

-}


type Typed creator tag accessRight untyped
    = Typed tag untyped


type Tagged
    = Tagged Never


type Public
    = Public Never


type Internal
    = Internal Never


type Checked
    = Checked Never



--


tag :
    tag
    -> untyped
    -> Typed creatorChecked_ tag accessRightPublic_ untyped
tag tag_ untyped =
    Typed tag_ untyped



--


untag : Typed tag_ creator_ Public untyped -> untyped
untag =
    \(Typed _ untyped) -> untyped


toPublic :
    tag
    ->
        (Typed creator tag accessRight_ untyped
         -> Typed creator tag accessRightPublic_ untyped
        )
toPublic tagConfirmation =
    \(Typed _ untyped) ->
        tag tagConfirmation untyped


wrapToCheckedPublic :
    tagWrap
    ->
        (Typed creator_ ( tagWrap, tagWrapped ) accessRight_ untyped
         -> Typed creatorChecked_ ( tagWrap, tagWrapped ) accessRightPublic_ untyped
        )
wrapToCheckedPublic tagConfirmation =
    \(Typed ( _, tagWrapped ) untyped) ->
        tag ( tagConfirmation, tagWrapped ) untyped



--


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


replace :
    untypedReplacement
    ->
        (Typed creator_ tag accessRight_ untyped_
         -> Typed Tagged tag accessRightPublic_ untypedReplacement
        )
replace untypedReplacement =
    \(Typed tag_ _) ->
        tag tag_ untypedReplacement


unwrap :
    Typed creator_ ( tagWrap_, tagWrapped ) accessRight untyped
    -> Typed Tagged tagWrapped accessRight untyped
unwrap =
    \(Typed ( _, wrappedTag ) untyped) ->
        tag wrappedTag untyped


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
        tag tag_ ( foodEarlier, foodLater )


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
        tag ( tagWrap, tag_ ) ( foodEarlier, foodLater )
