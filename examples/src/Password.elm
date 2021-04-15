module Password exposing (GoodPassword, UncheckedPassword, isGood, toOnlyDots)

import Set exposing (Set)
import Val exposing (Checked, Internal, Tagged, Val, isChecked, tag)


type alias Password goodOrUnchecked =
    Val goodOrUnchecked PasswordTag Internal String


type PasswordTag
    = Password


type alias GoodPassword =
    Password Checked


type alias UncheckedPassword =
    Password Tagged


isGood : UncheckedPassword -> Result String GoodPassword
isGood passwordToTest =
    let
        passwordString =
            Val.internal Password passwordToTest
    in
    if (passwordString |> String.length) < 10 then
        Err "Use at lest 10 letters & symbols."

    else if Set.member passwordString commonPasswords then
        Err "Choose a less common password."

    else
        Ok (passwordToTest |> isChecked Password)


commonPasswords : Set String
commonPasswords =
    Set.fromList
        [ "password1234"
        , "secret1234"
        , "c001_p4ssw0rd"
        , "1234567890"

        --...
        ]


toOnlyDots : Password goodOrUnchecked -> String
toOnlyDots =
    Val.internal Password
        >> String.length
        >> (\length ->
                List.repeat length '·'
                    |> String.fromList
           )
