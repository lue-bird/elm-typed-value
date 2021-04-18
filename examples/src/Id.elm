module Id exposing (Id, random, toString)

import Random
import Typed exposing (Checked, Internal, Typed, isChecked, tag)


type alias Id =
    Typed Checked IdTag Internal String


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
    internalVal Id
