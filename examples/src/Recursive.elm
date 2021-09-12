module Recursive exposing (Comment)

{-| One limit of `Typed`. In this example: consider using a tree instead.
-}

import Typed exposing (Public, Tagged, Typed)


type alias Comment =
    Typed
        Tagged
        CommentTag
        Public
        { message : String
        , responses : Maybe Comment
        }


type CommentTag
    = CommentTag Never
