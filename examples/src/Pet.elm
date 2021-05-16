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
    = Cat Never


type DogTag
    = Dog Never


sit : Dog -> Dog
sit =
    Typed.map (\p -> { p | mood = Neutral })


howdy : Cat
howdy =
    tag { name = "Howdy", mood = Happy, napsPerDay = 2.2 }
