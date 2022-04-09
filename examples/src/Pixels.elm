module Pixels exposing (Pixels, PixelsTag(..), ratio)

import Typed exposing (Public, Tagged, Typed, tag)


type alias Pixels =
    Typed Tagged PixelsTag Public Int


type PixelsTag
    = Pixels


ratio w h =
    ( w |> tag Pixels, h |> tag Pixels )
