module Pet exposing (Cat, Dog)

import Typed exposing (Public, Tagged, Typed, tag)


type alias Pet tag specificProperties =
    Typed
        Tagged
        tag
        Public
        { specificProperties | name : String, mood : Mood }


type Mood
    = Happy
    | Neutral


type alias Cat =
    Pet CatTag { napsPerDay : Float }


type alias Dog =
    Pet DogTag { barksPerDay : Float }


type CatTag
    = Cat


type DogTag
    = Dog


sit : Dog -> Dog
sit =
    Typed.map (\d -> { d | mood = Neutral })


howdy : Cat
howdy =
    { name = "Howdy", mood = Happy, napsPerDay = 2.2 }
        |> tag Cat
