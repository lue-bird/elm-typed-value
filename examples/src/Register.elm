module User exposing (main)

import Browser
import Password exposing (GoodPassword, UncheckedPassword)
import Html exposing (button, text)
import Html.Attributes exposing (value)
import Html.Events exposing (onClick, onInput)
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


main : Program () Model Msg
main =
    Browser.sandbox
        { init = initModel
        , view = view
        , update = update
        }

type alias Model =
    { passwordTypedIntoRegister : UncheckedPassword
    , loggedIn : LoggedIn
    }

type LoggedIn
    = LoggedIn { userPassword : GoodPassword }
    | NotLoggedIn

initModel =
    { passwordTypedIntoRegister = tag ""
    , loggedIn = NotLoggedIn
    }

type Msg
    = PasswordTypedIntoRegisterChanged UncheckedPassword
    | Register GoodPassword

update msg model =
    case msg of
        PasswordTypedIntoRegisterChanged uncheckedPassword ->
            { model
              | passwordTypedIntoRegister = uncheckedPassword
            }
        
        Register goodPassword ->
            { model
                | passwordTypedIntoRegister = tag ""
                , loggedIn =
                    LoggedIn { userPassword = goodPassword }
            }


view { passwordTypedIntoRegister } =
    Html.div []
        [ Html.div [] [ text "register" ]
        , Html.input
            [ onInput (tag >> PasswordTypedIntoRegisterChanged)
            , value (Password.toOnlyDots passwordTypedIntoRegister)
            ]
            []
        , case Password.isGood passwordTypedIntoRegister of
            Ok goodPassword ->
                Html.button
                    [ onClick (Register goodPassword)
                    ]
                    [ text "Create account" ]
            Err message ->
                text message
        ]
