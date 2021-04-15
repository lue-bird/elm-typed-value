module Id exposing (Id, random, toString)

import Random
import Val exposing (Checked, Internal, Val, isChecked, tag)


type alias Id =
    Val Checked IdTag Internal String


type IdTag
    = Id


random : Random.Generator Id
random =
    Random.list 16
        (Random.int (Char.toCode 'A') (Char.toCode 'z')
            |> Random.map Char.fromCode
        )
        |> Random.map String.fromList
        |> Random.map (tag >> isChecked Id)


toString : Id -> String
toString =
    Val.internal Id
