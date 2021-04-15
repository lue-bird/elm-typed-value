module Pixels exposing (Pixels, ratio)

import Val exposing (Public, Tagged, Val, tag)


type alias Pixels =
    Val Tagged PixelsTag Public Int


type PixelsTag
    = Pixels Never



-- use a type annotation to say what the result is


ratio : Int -> Int -> ( Pixels, Pixels )
ratio w h =
    ( tag w, tag h )
