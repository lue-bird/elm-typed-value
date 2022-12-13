module Password exposing (PasswordGood, PasswordUnchecked, toChecked, length, unchecked)

import Set exposing (Set)
import Typed exposing (Checked, Internal, Tagged, Typed, internal, tag)


type alias Password goodOrUnchecked =
    Typed goodOrUnchecked PasswordTag Internal String


type PasswordTag
    = Password


type alias PasswordGood =
    Password Checked


type alias PasswordUnchecked =
    Password Tagged


unchecked : String -> PasswordUnchecked
unchecked =
    tag Password


toChecked : PasswordUnchecked -> Result String PasswordGood
toChecked passwordToTest =
    let
        passwordString =
            internal Password passwordToTest
    in
    if (passwordString |> String.length) < 10 then
        Err "use >= 10 letters & symbols"

    else if Set.member passwordString commonPasswords then
        Err "choose a less common password"

    else
        Ok (passwordToTest |> Typed.toChecked Password)


commonPasswords : Set String
commonPasswords =
    Set.fromList
        [ "password1234"
        , "secret1234"
        , "c001_p4ssw0rd"
        , "1234567890"

        --...
        ]


length : Password goodOrUnchecked_ -> Int
length =
    \password ->
        password
            |> internal Password
            |> String.length
