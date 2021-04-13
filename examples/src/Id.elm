module Id exposing (Id, random, toString)

import Random
import Typed
    exposing
        ( Checked
        , CheckedHidden
        , Tagged
        , TaggedHidden
        , hiddenValueIn
        , isChecked
        , tag
        )

type alias Id =
    CheckedHidden IdTag CurrentImplementation

-- left as an implementation detail
-- might change in the future
-- but the API should stay the same
type alias CurrentImplementation =
    String

type IdTag = Id

random : Random.Generator Id
random =
    Random.list 16 ({-...-})
        |> Random.map (isChecked Id)

toString : Id -> String
toString =
    hiddenValueIn Id
