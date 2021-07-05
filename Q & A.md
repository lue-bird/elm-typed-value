## Why this, why that

#### These `something_` type variables

The "_" at the end shows that this type variable is used only in this place.

Our types have a lot of type variables, most of them only used once.
If you see a -_ you know not to focus on these.

Attention: when type variable names are inferred, ..._ = "only used once" might not apply anymore.

```elm
alwaysTrue : a_ -> Bool

when : (a -> Bool) -> a -> Maybe a

when alwaysTrue
--> gets inferred as a_ -> Maybe a_
```

Because of cases like that, The `elm-review` rules in [`elm-review-single-use-type-vars-end-with-underscore`](https://package.elm-lang.org/packages/lue-bird/elm-review-single-use-type-vars-end-with-underscore/latest/) are useful.
