# design decisions Q&A

## naming

Why is the type & module called `Typed`?
- I wanted the module name to be short
    - so that calling `TypedValue.map`/... isn't that verbose
- I wanted the module name to match the type name
    - because the methods operate on the type

Why are the extract methods called `val`?

- I wanted the extract method to be exposable
    - to make it short
    - `value` was a too common name (e.g. `Html.Attributes exposing (value)`)

Why call it `Internal` & `Public`?

- `Public` can be generally understood as accessible by everyone
- `Internal` is a less clear name than `AccessibleOnlyWithAccessToTheTagConstructor`, you'll probably get used to it easier, though

Why call it `Tagged` & `Checked`

- `Tagged`
    - points out the similarities to [joneshf/elm-tagged](https://package.elm-lang.org/packages/joneshf/elm-tagged/latest/)
    - you can guess that values `Tagged` with different `tag`s won't count as the same
- `Checked`
    - you can guess that not every `value` is considered valid. It must be `Checked` _somehow_

## Enough about my choices

I'm very much open to change stuff in the future, **so share your thoughts**!
If you want, post something in 'Discussions'.
