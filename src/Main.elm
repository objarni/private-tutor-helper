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
    , page : Page
    }


type Page
    = MainPage
    | PupilPage PupilId
    | LessonPage LessonId


type alias Pupil =
    { name : String
    , title : String
    , journal : List Lesson
    }


type alias Lesson =
    { date : String
    , thisfocus : String
    }


type alias PupilId =
    String


type alias DateString =
    String


type alias LessonId =
    { pupilId : String
    , date : String
    }


type Msg
    = GotJson (Result Http.Error (List Pupil))
    | ViewPupils
    | ViewPupil PupilId
    | ViewLesson LessonId


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
      , page = MainPage
      }
    , Http.get
        { url = "/journal.json"
        , expect = Http.expectJson GotJson jsonDecoder
        }
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    let
        selectedPupil =
            findSelectedPupil model
    in
    case msg of
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

        ViewPupils ->
            ( mainModel model "Viewing pupils"
            , Cmd.none
            )

        ViewPupil pupil ->
            ( { model
                | page = PupilPage pupil
                , statusText = "Viewing " ++ pupil
              }
            , Cmd.none
            )

        ViewLesson { date } ->
            ( { model
                | statusText = "Looking at " ++ date
                , page =
                    LessonPage
                        { pupilId = selectedPupil
                        , date = date
                        }
              }
            , Cmd.none
            )


findSelectedPupil : Model -> PupilId
findSelectedPupil { pupils, page } =
    case page of
        MainPage ->
            ""

        PupilPage pupilId ->
            pupilId

        LessonPage { pupilId } ->
            pupilId


mainModel : Model -> String -> Model
mainModel model text =
    { model
        | page = MainPage
        , statusText = text
    }


view model =
    Element.layout []
        (viewElement model)


viewElement : Model -> Element Msg
viewElement model =
    let
        content =
            case model.page of
                MainPage ->
                    pupilsElement model.pupils

                PupilPage pupilId ->
                    pupilPageElement (lookup pupilId model)

                LessonPage lessonId ->
                    lessonPageElement
    in
    Element.column
        [ Element.centerX
        , Element.spacing bigSpace
        ]
        [ headerElement model.statusText
        , content
        ]


lessonPageElement : Element Msg
lessonPageElement =
    Element.text "TODO"


lookup : PupilId -> Model -> Pupil
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
        , lessonsElement journal name
        , toMainPageElement
        ]


lessonsElement lessons pupilId =
    let
        lessonText { date, thisfocus } =
            String.slice 0 35 (date ++ ": " ++ thisfocus) ++ ".."

        lessonElement ({ date } as lesson) =
            let
                lessonId =
                    { pupilId = pupilId
                    , date = date
                    }
            in
            buttonElement (lessonText lesson) (ViewLesson lessonId)

        lessonComparison { date } =
            date

        sortDescending =
            List.sortBy lessonComparison >> List.reverse
    in
    Element.column
        [ Element.spacing smallSpace
        , Element.centerX
        ]
        (List.map
            lessonElement
            (sortDescending lessons)
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
    Element.wrappedRow
        [ Element.spacing smallSpace
        , Element.centerX
        ]
        (List.map (\{ name, title } -> pupilButtonElement name) pupils)


pupilButtonElement pupil =
    buttonElement pupil (ViewPupil pupil)


buttonElement : String -> Msg -> Element Msg
buttonElement buttonText onPressMsg =
    Element.el
        [ bgBlue
        , fgWhite
        , roundedBorder
        , Element.alignLeft
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
                lessonDecoder
            )
        )


lessonDecoder =
    D.map2 Lesson
        (D.field "Date" D.string)
        (D.field "ThisFocus" D.string)


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
