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


type alias Model =
    { pupils : List Pupil
    , statusText : String
    , selectedPupil : Maybe String
    }


type alias Pupil =
    { name : String
    , title : String
    , journal : List String
    }


type Msg
    = ViewPupil String
    | ViewPupils
    | GotJson (Result Http.Error (List Pupil))


main : Program () Model Msg
main =
    Browser.element
        { init = initialModel
        , update = update
        , view = view
        , subscriptions = subscriptions
        }


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none


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
        (viewElement model)


viewElement : Model -> Element Msg
viewElement model =
    let
        content =
            case model.selectedPupil of
                Nothing ->
                    pupilsElement model.pupils

                Just pupil ->
                    pupilPageElement (lookup pupil model)
    in
    Element.column
        [ Element.centerX
        , Element.spacing bigSpace
        ]
        [ headerElement model.statusText
        , content
        ]


lookup : String -> Model -> Pupil
lookup pupilName { pupils } =
    let
        rightPupil pupil =
            pupil.name == pupilName

        filtered =
            List.filter rightPupil pupils
    in
    case filtered of
        [ x ] ->
            x

        _ ->
            Debug.todo "handle this"


pupilPageElement { name, title, journal } =
    Element.column [ Element.centerX, Element.spacing bigSpace ]
        [ Element.text ("Title: " ++ title)
        , lessonsElement journal
        , toMainPageElement
        ]


lessonsElement : List String -> Element Msg
lessonsElement lessons =
    let
        lessonElement lesson =
            buttonElement lesson ViewPupils
    in
    Element.wrappedRow [ Element.spacing smallSpace ]
        (List.map
            lessonElement
            lessons
        )


toMainPageElement =
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


headerElement text =
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


pupilsElement : List Pupil -> Element Msg
pupilsElement pupils =
    Element.wrappedRow [ Element.spacing smallSpace ]
        (List.map (\{ name, title } -> pupilButtonElement name) pupils)


pupilButtonElement pupil =
    buttonElement pupil (ViewPupil pupil)


buttonElement : String -> Msg -> Element Msg
buttonElement buttonText onPressMsg =
    Element.el
        [ bgBlue
        , fgWhite
        , roundedBorder
        , Element.padding smallSpace
        ]
        (Input.button []
            { onPress = Just onPressMsg
            , label = Element.text buttonText
            }
        )


jsonDecoder : D.Decoder (List Pupil)
jsonDecoder =
    D.field "Pupils"
        (D.list pupilDecoder)


pupilDecoder : D.Decoder Pupil
pupilDecoder =
    D.map3 Pupil
        (D.field "Name" D.string)
        (D.field "Title" D.string)
        (D.field "Journal"
            (D.list
                (D.field "Date" D.string)
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
