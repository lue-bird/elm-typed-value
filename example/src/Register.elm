module Register exposing (Event, Model, main, modelInitial, reactTo, ui)

import Browser
import Element as Ui exposing (rgb)
import Element.Background as Background
import Element.Font as Font
import Element.Input as UIn
import Html exposing (Html)
import Html.Attributes as Html
import Html.Events exposing (onClick, onInput)
import Password exposing (PasswordGood, PasswordUnchecked)


type alias Model =
    { loggedIn : LoggedIn
    }


main : Program () Model Event
main =
    Browser.sandbox
        { init = modelInitial
        , view = uiHtml
        , update = reactTo
        }


modelInitial : Model
modelInitial =
    { loggedIn =
        NotLoggedIn
            { passwordTyped =
                "" |> Password.unchecked
            }
    }


type LoggedIn
    = LoggedIn
        { -- no user can have an unchecked password
          userPassword : PasswordGood
        }
    | NotLoggedIn
        { -- accessing user-typed password is impossible
          passwordTyped : PasswordUnchecked
        }


type Event
    = PasswordEdited PasswordUnchecked
    | PasswordConfirmed PasswordGood


reactTo : Event -> Model -> Model
reactTo event =
    \model ->
        case event of
            PasswordEdited uncheckedPassword ->
                { model
                    | loggedIn =
                        NotLoggedIn
                            { passwordTyped = uncheckedPassword }
                }

            PasswordConfirmed passwordGood ->
                { model
                    | loggedIn =
                        LoggedIn { userPassword = passwordGood }
                }


uiHtml : Model -> Html Event
uiHtml =
    \model ->
        ui model
            |> Ui.layout
                [ Background.color (rgb 0 0 0)
                , Font.color (rgb 1 1 1)
                ]


ui : Model -> Ui.Element Event
ui =
    \{ loggedIn } ->
        case loggedIn of
            LoggedIn _ ->
                "registered"
                    |> Ui.text
                    |> Ui.el [ Ui.centerX ]

            NotLoggedIn { passwordTyped } ->
                [ "register" |> Ui.text
                , [ UIn.text []
                        { onChange =
                            \text ->
                                text
                                    |> Password.unchecked
                                    -- not accessible from now on
                                    |> PasswordEdited
                        , text =
                            String.repeat
                                (passwordTyped
                                    |> Password.length
                                )
                                "*"
                        , placeholder = Nothing
                        , label = "register" |> UIn.labelHidden
                        }
                  , case passwordTyped |> Password.toChecked of
                        Ok passwordGood ->
                            UIn.button []
                                { onPress = PasswordConfirmed passwordGood |> Just
                                , label = "password |> confirm" |> Ui.text
                                }

                        Err message ->
                            message |> Ui.text
                  ]
                    |> Ui.row
                        [ Ui.centerX
                        , Ui.spacing 5
                        ]
                ]
                    |> Ui.column
                        [ Ui.spacing 12
                        , Ui.centerY
                        , Ui.centerX
                        ]
