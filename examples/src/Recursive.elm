module Recursive exposing (Recursive)

import Typed exposing (Typed, Tagged, Public)

type alias Comment =
    Typed Tagged RecursiveTag Public
        { text : String
        , subComments : List Comment
        }

type CommentTag =
    CommentTag Never
