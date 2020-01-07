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
import Pupil exposing (..)


type alias Model =
    { pupils : List Pupil
    , statusText : String
    , page : Page
    , saving : Bool
    }


type Page
    = MainPage
    | AddingPupilPage AddingPupilPageData
    | PupilPage PupilId
    | LessonPage LessonId


type alias AddingPupilPageData =
    { nameIsValid : Bool
    , name : String
    }


type alias PupilId =
    String


type alias DateString =
    String


type alias LessonId =
    { pupilId : String
    , date : String
    }



-- @remind - rename these for readility


type Msg
    = GotPupils (Result Http.Error (List Pupil))
    | PutPupils (Result Http.Error String)
    | AddPupil
    | ViewPupils
    | ViewPupil PupilId
    | ViewLesson LessonId
    | CopyLesson LessonId
    | CreatePupil PupilId
    | SuggestNewPupilName PupilId


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
      , saving = False
      }
    , Http.get
        { url = "/journal.json"
        , expect = Http.expectJson GotPupils pupilsFromJSON
        }
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    let
        selectedPupilId =
            findSelectedPupilId model
    in
    case msg of
        GotPupils result ->
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
                        { pupilId = selectedPupilId
                        , date = date
                        }
              }
            , Cmd.none
            )

        CopyLesson lessonId ->
            let
                oldLesson =
                    lookupLesson lessonId model

                newLesson : Lesson
                newLesson =
                    { oldLesson
                        | date = "2020-01-01"
                    }

                oldPupil =
                    lookupPupil selectedPupilId model

                newJournal =
                    oldPupil.journal ++ [ newLesson ]

                newPupil =
                    { oldPupil | journal = newJournal }

                newPupils =
                    replacePupil model.pupils selectedPupilId newPupil

                newModel =
                    { model
                        | pupils = newPupils
                        , statusText = "Lesson copied"
                        , saving = True
                    }
            in
            ( newModel
            , saveCommand newModel.pupils
            )

        PutPupils _ ->
            ( { model | saving = False }, Cmd.none )

        AddPupil ->
            ( { model
                | page =
                    AddingPupilPage
                        { nameIsValid = False
                        , name = "<fill in name here>"
                        }
                , statusText = "Add new pupil"
              }
            , Cmd.none
            )

        SuggestNewPupilName name ->
            ( { model
                | page =
                    AddingPupilPage
                        { nameIsValid = True
                        , name = name
                        }
              }
            , Cmd.none
            )

        CreatePupil pupilId ->
            let
                newPupil =
                    { name = pupilId
                    , title = ""
                    , journal = []
                    }

                newModel =
                    { model
                        | pupils = model.pupils ++ [ newPupil ]
                        , page = MainPage
                        , statusText = "New pupil added"
                    }
            in
            ( newModel
            , saveCommand newModel.pupils
            )


saveCommand : List Pupil -> Cmd Msg
saveCommand pupils =
    Http.post
        { url = "/save"
        , body = Http.stringBody "application/json" <| pupilsToJSONString pupils
        , expect = Http.expectString PutPupils
        }


findSelectedPupilId : Model -> PupilId
findSelectedPupilId { pupils, page } =
    case page of
        MainPage ->
            ""

        AddingPupilPage _ ->
            ""

        PupilPage pupilId ->
            pupilId

        LessonPage { pupilId } ->
            pupilId


replacePupil : List Pupil -> PupilId -> Pupil -> List Pupil
replacePupil pupils pupilId newPupil =
    let
        replaceInner p =
            case p.name == pupilId of
                True ->
                    newPupil

                False ->
                    p
    in
    List.map replaceInner pupils


mainModel : Model -> String -> Model
mainModel model text =
    { model
        | page = MainPage
        , statusText = text
    }


view model =
    let
        savingText =
            if model.saving then
                "Saving..."

            else
                ""
    in
    Element.layout
        [ Element.inFront
            (Element.text savingText)
        ]
        (viewElement model)


viewElement : Model -> Element Msg
viewElement model =
    let
        content =
            case model.page of
                MainPage ->
                    pupilsElement model.pupils

                AddingPupilPage pageData ->
                    addPupilElement pageData

                PupilPage pupilId ->
                    pupilPageElement (lookupPupil pupilId model)

                LessonPage lessonId ->
                    lessonPageElement (lookupLesson lessonId model)
    in
    Element.column
        [ Element.centerX
        , Element.spacing bigSpace
        ]
        [ headerElement model.statusText
        , content
        ]


lessonPageElement : Lesson -> Element Msg
lessonPageElement lesson =
    Element.column []
        [ Element.text lesson.date
        , Element.text lesson.thisfocus
        , Element.text lesson.location
        , Element.text lesson.homework
        , Element.text lesson.nextfocus
        , toMainPageElement
        ]


addPupilElement : AddingPupilPageData -> Element Msg
addPupilElement pageData =
    Element.column []
        [ Input.text []
            { onChange = \x -> SuggestNewPupilName x
            , text = pageData.name
            , placeholder = Nothing
            , label = Input.labelAbove [] (Element.text "Pupil name")
            }
        , buttonElement "Save" <| CreatePupil pageData.name
        ]


lookupPupil : PupilId -> Model -> Pupil
lookupPupil pupilName { pupils } =
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


lookupLesson : LessonId -> Model -> Lesson
lookupLesson { pupilId, date } ({ pupils } as model) =
    let
        rightPupil =
            lookupPupil pupilId model

        rightLesson lesson =
            lesson.date == date

        filtered =
            List.filter rightLesson rightPupil.journal
    in
    case List.head filtered of
        Just x ->
            x

        Nothing ->
            Debug.todo "IMPOSSIBLE!"


pupilPageElement { name, title, journal } =
    Element.column [ Element.centerX, Element.spacing bigSpace ]
        [ Element.text ("Title: " ++ title)
        , lessonsElement journal name
        , toMainPageElement
        ]


lessonsElement lessons pupilId =
    let
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
            (lessonElement pupilId)
            (sortDescending lessons)
        )


lessonElement pupilId lesson =
    let
        lessonText : Lesson -> String
        lessonText { date, thisfocus } =
            String.slice 0 35 (date ++ ": " ++ thisfocus) ++ ".."

        lessonId =
            { pupilId = pupilId
            , date = lesson.date
            }
    in
    Element.el
        [ Border.width 1
        , Element.padding 9
        , Element.width (Element.px 350)
        , Border.rounded 3
        , Border.color <| Element.rgb255 199 199 199
        ]
        (Element.column [ Element.spacing smallSpace ]
            [ Element.text <| lesson.date
            , Element.paragraph [] [ Element.text lesson.thisfocus ]
            , Element.row [ Element.spacing smallSpace ]
                [ buttonElement "View" (ViewLesson lessonId)
                , buttonElement "Copy" (CopyLesson lessonId)
                ]
            ]
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


headerElement statusText =
    Element.column
        [ Element.spacing bigSpace
        , Element.centerX
        ]
        [ Element.el
            [ Element.centerX
            , Font.size 30
            ]
            (Element.text "Lesson Journal")
        , Element.el
            [ Element.centerX
            ]
            (Element.text statusText)
        ]


pupilsElement : List Pupil -> Element Msg
pupilsElement pupils =
    Element.column []
        [ Element.wrappedRow
            [ Element.spacing smallSpace
            , Element.centerX
            ]
            (List.map (\{ name } -> pupilButtonElement name) pupils)
        , buttonElement "Add Pupil" AddPupil
        ]


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
