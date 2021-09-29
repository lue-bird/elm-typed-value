module UsePixels exposing (defaultWindowWidth)

import Pixels exposing (Pixels)
import Typed exposing (tag)


defaultWindowWidth : Pixels
defaultWindowWidth =
    Typed.map2 (+)
        (tag 700)
        (borderWidth |> Typed.map ((*) 2))


borderWidth : Pixels
borderWidth =
    tag 5
