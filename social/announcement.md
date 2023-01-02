## 8.0.0

[`Typed`](https://dark.elm.dmy.fr/packages/lue-bird/elm-typed-value/latest/) 8's power:
wrapping a generic typed.

As an example how [`KeySet`](https://dark.elm.dmy.fr/packages/lue-bird/elm-keyset/latest/KeySet)
uses [`Typed`](https://dark.elm.dmy.fr/packages/lue-bird/elm-typed-value/latest/)
```elm
type alias Ordering a tag =
    Typed Checked tag Public (a -> a -> Order)

reverse : Ordering subject tag -> Ordering subject ( Reverse, tag )
```
`Ordering` operations couldn't be represented using normal opaque types
because you can't generically look inside.

You'd need to store a tag, but having access to the tag ruins the promise
that only the `module` with the tag can create `Ordering`s with that tag.

```elm
module Int.Order exposing (increasing, Increasing)

increasing : Ordering Int Increasing
type Increasing = Increasing
```
```elm
module Float.Order exposing (increasing, Increasing)

increasing : Ordering Float Increasing
type Increasing = Increasing
```
```elm
module KeySet exposing (KeySet, insert, remove)

type alias Sorting element tag key =
    Typed
        Checked
        ( SortingTag, tag )
        Public
        { toKey : element -> key
        , keyOrder : element -> element -> Order
        }

type SortingTag
    = Sorting

sortingKey :
    Typed Checked keyTag Public (element -> key)
    -> Ordering key keyOrderTag
    -> Sorting element ( keyTag, keyOrderTag ) key

type alias KeySet element tag =
    Typed Checked tag Internal ..internals..

insert :
    Sorting element tag key_
    -> element
    -> KeySet element tag
    -> KeySet element tag

remove :
    Sorting element tag key
    -> key
    -> KeySet element tag
    -> KeySet element tag
```
```elm
KeySet.empty
    |> KeySet.insert Float.Order.increasing 3
    |> KeySet.remove Int.Order.increasing 4.0 -- compile-time error
```

  - Each unique `Sorting` has a unique `tag` combination `( toKeyTag, keyOrderTag )`

  - `KeySet` enforces that all operations need a `Sorting` with the same `tag`

Therefore, the supplied `toKey` and `keyOrdering` functions are enforced to be the same across every operation.

What's new in version 8 is how we can preserve tags through wrapping them
```elm
type SortingTag
    = Sorting

sortingKey :
    Typed Checked keyTag Public (element -> key)
    -> Ordering key keyOrderTag
    -> Sorting element ( keyTag, keyOrderTag ) key
sortingKey toKeyTyped keyOrdering =
    toKeyTyped
        |> Typed.wrapAnd keyOrdering
        --: Typed ( keyTag, keyOrderTag ) Tagged Public ...
        |> Typed.mapToWrap Sorting
            (\( toKey, keyOrder ) ->
                { toKey = toKey
                , keyOrder = keyOrder
                }
            )
```
in a simpler example: implementing `Order.reverse`
```elm
type Reverse
    = Reverse

reverse : Ordering subject tag -> Ordering subject ( Reverse, tag )
reverse =
    Typed.mapToWrap Reverse (\order -> \a b -> order b a)
```
Notice how we don't have access to the tag of the argument
but can still safely show it in the signature.

How did we do this in version 7? Unsafe phantom types 🤮:
```elm
type Reverse tag
    = Reverse

reverse : Ordering subject tag -> Ordering subject (Reverse tag)
reverse =
    Typed.mapTo Reverse (\order -> \a b -> order b a)

reverseOops : Ordering subject orderTag -> Ordering subject (Reverse tag)
```
The reversed tag can accidentally be anything. It's a free variable :(

Sadly that's sometimes more readable for multiple tag arguments. A quick solution:
```elm
type alias Reverse orderTag =
    ( ReverseTag, orderTag )

type ReverseTag
    = Reverse

reverse : Ordering subject tag -> Ordering subject (Reverse tag)
reverse =
    Typed.mapToWrap Reverse (\order -> \a b -> order b a)
```
Makes it safe, makes brain happy!
