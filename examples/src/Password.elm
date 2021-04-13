module Password exposing (GoodPassword, UncheckedPassword, isGood, toOnlyDots)

import Set
import Typed
    exposing
        ( Anyone
        , Checked
        , CheckedHidden
        , NoUser
        , Tagged
        , TaggedHidden
        , Typed
        , hiddenValueIn
        , isChecked
        , tag
        )


type alias Password goodOrUnchecked =
    Typed PasswordTag String { goodOrUnchecked | canAccess : NoUser }


type PasswordTag
    = Password


type alias GoodPassword =
    Password { createdBy : NoUser }


type alias UncheckedPassword =
    Password { createdBy : Anyone }


isGood : UncheckedPassword -> Result String GoodPassword
isGood passwordToTest =
    let
        passwordString =
            hiddenValueIn Password passwordToTest
    in
    if (passwordString |> String.length) < 10 then
        Err "Use at lest 10 letters & symbols."

    else if Set.member passwordString commonPasswords then
        Err "Choose a less common password."

    else
        Ok (passwordToTest |> isChecked Password)


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
    hiddenValueIn Password
        >> String.length
        >> (\length ->
                List.repeat length '·'
                    |> String.fromList
           )
