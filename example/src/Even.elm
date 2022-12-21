module Even exposing (Even, add, multiply, n0, n2)

import Typed exposing (Checked, Public, Typed, tag)


type alias Even =
    Typed Checked EvenTag Public Int


type EvenTag
    = -- don't expose this variant
      Even


multiply : Int -> Even -> Even
multiply factor =
    Typed.mapTo Even (\int -> int * factor)


add : Even -> Even -> Even
add toAddEven =
    \even ->
        (even |> Typed.and toAddEven)
            |> Typed.mapTo Even
                (\( int, toAddInt ) -> int + toAddInt)


n0 : Even
n0 =
    0 |> tag Even


n2 : Even
n2 =
    2 |> tag Even
