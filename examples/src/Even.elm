module Even exposing (Even, add, multiply, n0, n2)

import Typed exposing (Checked, Public, Typed, isChecked, tag)


type alias Even =
    Typed Checked EvenTag Public Int


type
    EvenTag
    -- don't expose this constructor
    = Even


multiply : Int -> Even -> Even
multiply factor =
    \even ->
        even
            |> Typed.map (\int -> int * factor)
            |> isChecked Even


add : Even -> Even -> Even
add toAddEven =
    \even ->
        (even |> Typed.and toAddEven)
            |> Typed.map
                (\( int, toAddInt ) -> int + toAddInt)
            |> isChecked Even


n0 : Even
n0 =
    0 |> tag Even


n2 : Even
n2 =
    2 |> tag Even
