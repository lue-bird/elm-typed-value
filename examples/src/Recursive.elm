module Recursive exposing (Comment)

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
