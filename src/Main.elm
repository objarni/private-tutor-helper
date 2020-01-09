module Main exposing (main)

import Browser exposing (sandbox)
import Dict exposing (Dict)
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
    { pupils : Dict PupilId Pupil
    , statusText : String
    , page : Page
    , saving : Bool
    , todaysDate : String
    }


type Page
    = MainPage
    | AddingPupilPage AddingPupilPageData
    | PupilPage PupilId
    | LessonPage LessonId


type alias AddingPupilPageData =
    { nameError : Maybe String
    , name : String
    }


type alias DateString =
    String


type alias LessonId =
    { pupilId : String
    , date : String
    }



-- Msg name conventions
-- GotoXYZ --> a navigation message, switching page
-- Got/PutZYZ --> JSON response messages


type Msg
    = GotPupils (Result Http.Error (Dict PupilId Pupil))
    | PutPupils (Result Http.Error String)
    | GotoPageAddPupil
    | GotoPagePupils
    | GotoPagePupil PupilId
    | GotoPageLesson LessonId
    | CopyLesson LessonId
    | CreatePupil PupilId
    | SuggestNewPupilName PupilId


main : Program String Model Msg
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


initialModel : String -> ( Model, Cmd Msg )
initialModel dateNow =
    ( { pupils = Dict.empty
      , statusText = "Loading pupils..."
      , page = MainPage
      , saving = False
      , todaysDate = dateNow
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
                    if True then
                        ( mainModel
                            { model
                                | pupils = loadedPupils
                            }
                            "Pupils loaded"
                        , Cmd.none
                        )

                    else
                        ( { model
                            | pupils = loadedPupils
                            , page = LessonPage { pupilId = "Maria Bylund", date = "2018-07-15" }
                            , statusText = "Debug landing page"
                          }
                        , Cmd.none
                        )

        GotoPagePupils ->
            ( mainModel model "Viewing pupils"
            , Cmd.none
            )

        GotoPagePupil pupil ->
            ( { model
                | page = PupilPage pupil
                , statusText = "Viewing " ++ pupil
              }
            , Cmd.none
            )

        GotoPageLesson { date } ->
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
                        | date = model.todaysDate
                    }

                oldPupil =
                    case lookupPupil selectedPupilId model of
                        Just p ->
                            p

                        Nothing ->
                            Debug.todo "How to express this better?"

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

        GotoPageAddPupil ->
            ( { model
                | page =
                    AddingPupilPage
                        { nameError = Just "Name is empty"
                        , name = ""
                        }
                , statusText = "Add new pupil"
              }
            , Cmd.none
            )

        SuggestNewPupilName name ->
            let
                notEmpty : String -> Bool
                notEmpty =
                    not << String.isEmpty

                unique : String -> Bool
                unique pupilId =
                    case lookupPupil pupilId model of
                        Just pupil ->
                            False

                        Nothing ->
                            True

                nameError =
                    case ( notEmpty name, unique name ) of
                        ( False, _ ) ->
                            Just "Name is empty"

                        ( _, False ) ->
                            Just "Name not unique"

                        _ ->
                            Nothing
            in
            ( { model
                | page =
                    AddingPupilPage
                        { nameError = nameError
                        , name = name
                        }
              }
            , Cmd.none
            )

        CreatePupil pupilId ->
            -- @remind case is quite big - separate function?
            let
                newPupil =
                    { title = ""
                    , journal =
                        [ { date = model.todaysDate
                          , thisfocus = "Learn stuff"
                          , nextfocus = "Learn more stuff"
                          , homework = "Practice, practice, practice"
                          , location = "Remote"
                          }
                        ]
                    }

                newModel =
                    let
                        insertPupil : Maybe Pupil -> Maybe Pupil
                        insertPupil p =
                            Just newPupil
                    in
                    { model
                        | pupils = Dict.update pupilId insertPupil model.pupils
                        , page = MainPage
                        , statusText = "New pupil added"
                    }
            in
            ( newModel
            , saveCommand newModel.pupils
            )


saveCommand : Dict PupilId Pupil -> Cmd Msg
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


replacePupil : Dict PupilId Pupil -> PupilId -> Pupil -> Dict PupilId Pupil
replacePupil pupils pupilId newPupil =
    let
        updatePupil pupil =
            Just newPupil
    in
    Dict.update pupilId updatePupil pupils


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
                    case lookupPupil pupilId model of
                        Just p ->
                            pupilPageElement pupilId p

                        Nothing ->
                            Debug.todo "Ugh"

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


type alias LessonProperty =
    { field : String
    , value : String
    }


lessonPageElement : Lesson -> Element Msg
lessonPageElement lesson =
    let
        data =
            [ { field = "Date"
              , value = lesson.date
              }
            , { field = "Focus"
              , value = lesson.thisfocus
              }
            , { field = "Next time"
              , value = lesson.nextfocus
              }
            , { field = "Homework"
              , value = lesson.homework
              }
            ]
    in
    Element.table
        [ Element.width (Element.maximum containerWidth Element.fill)
        , Element.spacing smallSpace
        ]
        { data = data
        , columns =
            [ { header = Element.none
              , width = Element.px 150
              , view = \prop -> Element.text prop.field
              }
            , { header = Element.none
              , width = Element.fill
              , view = \prop -> Element.paragraph [] [ Element.text prop.value ]
              }
            ]
        }


addPupilElement : AddingPupilPageData -> Element Msg
addPupilElement pageData =
    let
        button =
            case pageData.nameError of
                Nothing ->
                    buttonElement "Save" <| CreatePupil pageData.name

                Just error ->
                    disabledButtonElement "Save"
    in
    Element.column []
        [ Input.text []
            { onChange = \x -> SuggestNewPupilName x
            , text = pageData.name
            , placeholder = Nothing
            , label = Input.labelAbove [] (Element.text "Pupil name")
            }
        , Element.text
            (case pageData.nameError of
                Nothing ->
                    ""

                Just error ->
                    "Warning: " ++ error
            )
        , Element.el [ Element.centerX, Element.padding smallSpace ]
            button
        ]


lookupPupil : PupilId -> Model -> Maybe Pupil
lookupPupil pupilName { pupils } =
    Dict.get pupilName pupils


lookupLesson : LessonId -> Model -> Lesson
lookupLesson { pupilId, date } { pupils } =
    let
        maybeRightPupil =
            Dict.get pupilId pupils

        rightLesson lesson =
            lesson.date == date

        filtered =
            case maybeRightPupil of
                Just pupil ->
                    List.filter rightLesson pupil.journal

                Nothing ->
                    []
    in
    case List.head filtered of
        Just x ->
            x

        Nothing ->
            Debug.todo "IMPOSSIBLE!"


pupilPageElement name { title, journal } =
    Element.column [ Element.centerX, Element.spacing bigSpace ]
        [ Element.text ("Title: " ++ title)
        , lessonsElement journal name
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
                [ buttonElement "View" (GotoPageLesson lessonId)
                , buttonElement "Copy" (CopyLesson lessonId)
                ]
            ]
        )


headerElement statusText =
    Element.column
        [ Element.spacing bigSpace
        , Element.centerX
        ]
        [ Element.el
            [ Element.centerX, Element.padding bigSpace ]
            (Input.button
                [ Element.padding bigSpace
                , Font.size 30
                , bgRed
                , fgWhite
                , roundedBorder
                ]
                { onPress = Just GotoPagePupils
                , label = Element.text "Lesson Journal"
                }
            )
        , Element.el
            [ Element.centerX
            ]
            (Element.text statusText)
        ]


pupilsElement : Dict PupilId Pupil -> Element Msg
pupilsElement pupils =
    let
        pupilNames =
            Dict.keys pupils
    in
    Element.column [ Element.padding bigSpace ]
        [ Element.wrappedRow
            [ Element.spacing smallSpace
            , Element.centerX
            ]
            (List.map (\name -> pupilButtonElement name) pupilNames)
        , Element.el [ Element.centerX, Element.padding bigSpace ]
            (buttonElement "Add Pupil" GotoPageAddPupil)
        ]


pupilButtonElement pupil =
    buttonElement pupil (GotoPagePupil pupil)


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


disabledButtonElement : String -> Element Msg
disabledButtonElement buttonText =
    Element.el
        [ bgGray
        , fgWhite
        , roundedBorder
        , Element.alignLeft
        , Element.padding smallSpace
        ]
        (Input.button []
            { onPress = Nothing
            , label = Element.text buttonText
            }
        )


bgBlue =
    Background.color (Element.rgb255 0 140 165)


bgGray =
    Background.color (Element.rgb255 100 100 100)


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


containerWidth =
    1000
