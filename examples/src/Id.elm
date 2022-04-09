module Id exposing (Id, random, toString)

import Random
import Typed exposing (Checked, Internal, Typed, internal, isChecked, tag)


type alias Id =
    Typed Checked IdTag Internal (List Int)


type IdTag
    = Id


random : Random.Generator Id
random =
    Random.list 2
        (Random.int Random.minInt Random.maxInt)
        |> Random.map (tag Id)


toString : Id -> String
toString =
    \id ->
        id
            |> internal Id
            |> List.map String.fromInt
            |> String.join ")"
