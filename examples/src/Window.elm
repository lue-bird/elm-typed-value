module Window exposing (defaultWidth)

import Pixels exposing (Pixels, PixelsTag(..))
import Typed exposing (mapToTyped, tag, untag)


defaultWidth =
    innerWidth
        |> Typed.and borderWidth
        |> Typed.map
            (\( inner, border ) -> inner + border * 2)


innerWidth =
    700 |> tag Pixels


borderWidth =
    5 |> tag Pixels
