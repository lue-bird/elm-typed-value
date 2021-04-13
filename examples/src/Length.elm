module Length exposing (Length, Meters, Millimeters)

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


type alias Length unit =
    Tagged (LengthUnit unit) Float


type LengthUnit unit
    = LengthUnit Never


type Meters
    = Meters Never


type Millimeters
    = Millimeters Never


metersToMillimeters : Length Meters -> Length Millimeters
metersToMillimeters =
    Typed.map ((*) 1000)


heightEiffelTower : Length Meters
heightEiffelTower =
    tag 300



{-
   notPossible =
       heightEiffelTower |> metersToMillimeters
       |> metersToMillimeters

-}
