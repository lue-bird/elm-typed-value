module UsePixels exposing (defaultWindowWidth)

import Pixels exposing (Pixels)
import Val exposing (tag)

defaultWindowWidth : Pixels
defaultWindowWidth =
    Val.map2 (+)
        (tag 700)
        (borderWidth |> Val.map ((*) 2))

borderWidth : Pixels
borderWidth =
    tag 5
