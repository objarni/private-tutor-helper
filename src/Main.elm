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


type alias Pupil =
    { name : String
    , title : String
    }


type alias Model =
    { pupils : List Pupil
    , statusText : String
    , selectedPupil : Maybe String
    }


type Msg
    = ViewPupil String
    | ViewPupils
    | GotJson (Result Http.Error (List Pupil))


initialModel _ =
    ( { pupils = []
      , statusText = "Loading pupils..."
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
                , statusText = "Viewing " ++ pupil
              }
            , Cmd.none
            )

        ViewPupils ->
            ( mainModel model "Viewing pupils"
            , Cmd.none
            )

        GotJson result ->
            case result of
                Err _ ->
                    ( mainModel model "Http error!"
                    , Cmd.none
                    )

                Ok loadedPupils ->
                    ( mainModel
                        { model
                            | pupils = loadedPupils
                        }
                        "Pupils loaded"
                    , Cmd.none
                    )


mainModel : Model -> String -> Model
mainModel model text =
    { model
        | selectedPupil = Nothing
        , statusText = text
    }


view model =
    Element.layout []
        (mainColumn model)



-- remind: DRY up this function


mainColumn : Model -> Element Msg
mainColumn model =
    case model.selectedPupil of
        Nothing ->
            Element.column [ Element.centerX, Element.spacing bigSpace ]
                [ header model.statusText
                , listPupils model.pupils
                ]

        Just pupil ->
            Element.column [ Element.centerX, Element.spacing bigSpace ]
                [ header model.statusText
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
    Element.column
        [ Element.spacing bigSpace
        , Element.centerX
        ]
        [ Element.el
            [ Element.centerX
            , Font.size 30
            ]
            (Element.text "Lesson journal")
        , Element.el
            [ Element.centerX
            ]
            (Element.text text)
        ]


listPupils : List Pupil -> Element Msg
listPupils pupils =
    Element.wrappedRow [ Element.spacing smallSpace ]
        (List.map (\{ name, title } -> pupilButton name) pupils)


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


jsonDecoder : D.Decoder (List Pupil)
jsonDecoder =
    D.field "Pupils"
        (D.list
            (D.map2 Pupil
                (D.field "name" D.string)
                (D.field "title" D.string)
            )
        )


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
