module Pixels exposing (Pixels, ratio)

import Typed exposing (Public, Tagged, Typed, tag)


type alias Pixels =
    Typed Tagged PixelsTag Public Int


type PixelsTag
    = Pixels Never



-- use a type annotation to say what the result is


ratio : Int -> Int -> ( Pixels, Pixels )
ratio w h =
    ( tag w, tag h )
