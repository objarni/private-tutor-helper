module Main exposing (main)

import Browser exposing (sandbox)
import Element exposing (Element)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Html exposing (Html)
import Html.Events
import Http
import Json.Decode as D


main : Program () Model Msg
main =
    Browser.element
        { init = initialModel
        , update = update
        , view = view
        , subscriptions = subscriptions
        }


type alias Model =
    { pupils : List String
    , text : String
    , selectedPupil : Maybe String
    }


type Msg
    = ViewPupil String
    | ViewPupils
    | GotJson (Result Http.Error (List String))


initialModel _ =
    ( { pupils = []
      , text = ""
      , selectedPupil = Nothing
      }
    , Http.get
        { url = "/journal.json"
        , expect = Http.expectJson GotJson jsonDecoder
        }
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ViewPupil pupil ->
            ( { model
                | selectedPupil = Just pupil
              }
            , Cmd.none
            )

        ViewPupils ->
            ( { model
                | selectedPupil = Nothing
              }
            , Cmd.none
            )

        GotJson result ->
            case result of
                Err _ ->
                    ( { pupils = model.pupils
                      , text = "Http error"
                      , selectedPupil = Nothing
                      }
                    , Cmd.none
                    )

                Ok newPupils ->
                    ( { pupils = newPupils
                      , text = "Pick pupil"
                      , selectedPupil = Nothing
                      }
                    , Cmd.none
                    )


view model =
    Element.layout []
        (mainColumn model)


mainColumn : Model -> Element Msg
mainColumn model =
    case model.selectedPupil of
        Nothing ->
            Element.column [ Element.centerX, Element.spacing bigSpace ]
                [ header "Lesson Journal"
                , listPupils model.pupils
                ]

        Just pupil ->
            Element.column [ Element.centerX, Element.spacing bigSpace ]
                [ header ("Lesson Journal for " ++ pupil)
                , backLink
                ]


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none


backLink =
    Element.el
        [ bgBlue
        , fgWhite
        , roundedBorder
        , Element.centerX
        , Element.padding smallSpace
        ]
        (Input.button []
            { onPress = Just ViewPupils
            , label = Element.text " < Back"
            }
        )


header text =
    Element.el
        [ Element.padding bigSpace
        , Element.centerX
        ]
        (Element.el
            []
            (Element.text text)
        )


listPupils : List String -> Element Msg
listPupils pupils =
    Element.wrappedRow [ Element.spacing smallSpace ]
        (List.map (\txt -> pupilButton txt) pupils)


pupilButton : String -> Element Msg
pupilButton pupil =
    Element.el
        [ bgBlue
        , fgWhite
        , roundedBorder
        , Element.padding smallSpace
        ]
        (Input.button []
            { onPress = Just (ViewPupil pupil)
            , label = Element.text pupil
            }
        )


jsonDecoder : D.Decoder (List String)
jsonDecoder =
    D.field "Pupils" (D.list (D.field "Name" D.string))


bgBlue =
    Background.color (Element.rgb255 0 140 165)


bgRed =
    Background.color (Element.rgb255 140 10 10)


fgWhite =
    Font.color (Element.rgb255 255 255 255)


smallSpace =
    20


bigSpace =
    40


roundedBorder =
    Border.rounded 10
