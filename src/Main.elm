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
    { pupils : PupilLookup
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
    | EditLessonPage EditLessonData


type alias AddingPupilPageData =
    { nameError : Maybe String
    , name : String
    }



-- Msg name conventions
-- GotoXYZ --> a navigation message, switching page
-- Got/PutZYZ --> JSON response messages


type Msg
    = GotPupils (Result Http.Error PupilLookup)
    | PutPupils (Result Http.Error String)
    | GotoPageAddPupil
    | GotoPagePupils
    | GotoPagePupil PupilId
    | GotoPageLesson LessonId
    | GotoPageEditLesson EditLessonData
    | CopyLesson LessonId
    | DeleteLesson LessonId
    | CreatePupil PupilId
    | SuggestNewPupilName PupilId
    | SaveLesson EditLessonData


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
            ( gotPupilsUpdate model result
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
                | statusText = "Lesson for " ++ selectedPupilId ++ " at " ++ date
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
                newPupils =
                    opCopyLesson lessonId model.todaysDate model.pupils
            in
            savePupilsUpdate newPupils model.todaysDate "Lesson copied"

        DeleteLesson lessonId ->
            let
                newPupils =
                    opDeleteLesson lessonId model.pupils
            in
            savePupilsUpdate newPupils model.todaysDate "Lesson deleted"

        PutPupils _ ->
            ( { model
                | saving = False
                , statusText = "Journal saved."
              }
            , Cmd.none
            )

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

        GotoPageEditLesson ({ pupilId, dateString, lesson } as lessonData) ->
            ( { model
                | page = EditLessonPage lessonData
                , statusText = "Editing " ++ dateString ++ " of " ++ pupilId
              }
            , Cmd.none
            )

        SuggestNewPupilName name ->
            let
                nameError =
                    validateName name model
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
            let
                newPupils =
                    opCreatePupil pupilId model.todaysDate model.pupils
            in
            savePupilsUpdate newPupils model.todaysDate "New pupil added"

        SaveLesson editLessonData ->
            let
                newPupils =
                    opUpdateLesson editLessonData model.pupils

                text =
                    "Saving lesson "
                        ++ editLessonData.dateString
                        ++ " of "
                        ++ editLessonData.pupilId
                        ++ "..."
            in
            savePupilsUpdate newPupils model.todaysDate text


gotPupilsUpdate model httpResult =
    case httpResult of
        Err _ ->
            mainModel model "Http error!"

        Ok loadedPupils ->
            -- for debugging purposes ability to jump to specific page state
            if True then
                mainModel
                    { model
                        | pupils = loadedPupils
                    }
                    "Pupils loaded"

            else
                { model
                    | pupils = loadedPupils
                    , page =
                        EditLessonPage
                            { pupilId = "Test pupil"
                            , dateString = "2018-07-15"
                            , lesson =
                                { thisfocus = "def, return and argument grokking. functions as small programs. differentiate keywords, builtin functions, std.lib. read column values from .xls file"
                                , location = ""
                                , homework = "Read Start Trek movie list from .xls file, repeat previous excercise on that data"
                                , nextfocus = "Read two columns 'until' condition (her application)"
                                }
                            , oldDate = "2018-07-15"
                            }
                    , statusText = "Debug landing page"
                }


validateName : PupilId -> Model -> Maybe String
validateName name model =
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
    nameError


savePupilsUpdate : PupilLookup -> DateString -> String -> ( Model, Cmd Msg )
savePupilsUpdate pupils today text =
    ( { pupils = pupils
      , saving = True
      , statusText = text
      , page = MainPage
      , todaysDate = today
      }
    , Http.post
        { url = "/save"
        , body = Http.stringBody "application/json" <| pupilsToJSONString pupils
        , expect = Http.expectString PutPupils
        }
    )


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

        EditLessonPage { pupilId } ->
            pupilId


mainModel : Model -> String -> Model
mainModel model text =
    { model
        | page = MainPage
        , statusText = text
    }


view : Model -> Html Msg
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
            (Element.el [ fgGray, Font.italic ]
                (Element.text savingText)
            )
        ]
        (viewElement model)


viewElement : Model -> Element Msg
viewElement model =
    let
        content =
            case model.page of
                MainPage ->
                    pupilsPageElement model.pupils

                AddingPupilPage pageData ->
                    addPupilPageElement pageData

                PupilPage pupilId ->
                    case lookupPupil pupilId model of
                        Just p ->
                            pupilPageElement pupilId p

                        Nothing ->
                            Debug.todo "Ugh"

                LessonPage lessonId ->
                    case lookupLesson lessonId model of
                        Just lesson ->
                            lessonPageElement lesson

                        Nothing ->
                            Element.none

                EditLessonPage data ->
                    editLessonPageElement data
    in
    Element.column
        [ Element.centerX
        , Element.spacing bigSpace
        , Element.width (Element.maximum containerWidth Element.fill)
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
            [ { field = "Focus"
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
        ([ Element.width (Element.maximum containerWidth Element.fill)
         , Element.spacing smallSpace
         ]
            ++ lightBorder
        )
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


editLessonPageElement : EditLessonData -> Element Msg
editLessonPageElement { pupilId, dateString, lesson, oldDate } =
    let
        -- @remind add date editing field
        fieldInput : String -> String -> (String -> Lesson) -> Element Msg
        fieldInput fieldName fieldValue modifyLesson =
            Input.multiline [ Element.width <| Element.px 600 ]
                { text = fieldValue
                , placeholder = Nothing
                , spellcheck = True
                , label = Input.labelAbove [] (Element.text fieldName)
                , onChange =
                    \x ->
                        GotoPageEditLesson
                            { pupilId = pupilId
                            , dateString = dateString
                            , lesson = modifyLesson x
                            , oldDate = dateString
                            }
                }
    in
    Element.column
        [ Element.centerX
        , Element.spacing smallSpace
        , Element.padding bigSpace
        ]
        [ fieldInput
            "Focus"
            lesson.thisfocus
            (\x -> { lesson | thisfocus = x })
        , fieldInput "Next focus" lesson.nextfocus (\x -> { lesson | nextfocus = x })
        , fieldInput "Homework" lesson.homework (\x -> { lesson | homework = x })
        , Element.el [ Element.centerX ]
            (buttonElement
                "Save"
                (SaveLesson
                    { pupilId = pupilId
                    , dateString = dateString
                    , lesson = lesson
                    , oldDate = oldDate
                    }
                )
            )
        ]


addPupilPageElement : AddingPupilPageData -> Element Msg
addPupilPageElement pageData =
    let
        button =
            case pageData.nameError of
                Nothing ->
                    buttonElement "Save" <| CreatePupil pageData.name

                Just error ->
                    disabledButtonElement "Save"
    in
    Element.column [ Element.centerX ]
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


lookupLesson : LessonId -> Model -> Maybe Lesson
lookupLesson { pupilId, date } { pupils } =
    let
        maybeRightPupil =
            Dict.get pupilId pupils

        maybeLesson =
            case maybeRightPupil of
                Nothing ->
                    Nothing

                Just pupil ->
                    Dict.get date pupil.journal
    in
    maybeLesson


pupilPageElement name { title, journal } =
    Element.column
        [ Element.centerX
        , Element.spacing bigSpace
        ]
        [ Element.el [ Element.centerX ]
            (Element.text <| "Title: " ++ title)
        , lessonsElement journal name
        ]


lessonsElement : Dict String Lesson -> PupilId -> Element Msg
lessonsElement lessons pupilId =
    let
        lessonList : List String
        lessonList =
            Dict.keys lessons

        sortDescending : List String -> List String
        sortDescending =
            List.sortBy identity >> List.reverse

        sortedLessonIds =
            sortDescending lessonList

        makeLessonTuple : DateString -> ( DateString, Lesson )
        makeLessonTuple dateString =
            case Dict.get dateString lessons of
                Just lesson ->
                    ( dateString, lesson )

                Nothing ->
                    Debug.todo "wtf"

        sortedLessonTuples =
            List.map
                makeLessonTuple
                sortedLessonIds
    in
    Element.wrappedRow
        [ Element.spacing smallSpace ]
        (List.map
            (\( d, l ) -> lessonMasterElement pupilId l d)
            sortedLessonTuples
        )


lessonMasterElement : PupilId -> Lesson -> DateString -> Element Msg
lessonMasterElement pupilId lesson date =
    let
        lessonText : Lesson -> String
        lessonText { thisfocus } =
            String.slice 0 35 ("fixme" ++ ": " ++ thisfocus) ++ ".."

        lessonId =
            { pupilId = pupilId
            , date = date
            }
    in
    Element.el
        (lightBorder
            ++ [ Element.height <| Element.px 350
               , Element.width <| Element.px <| round <| containerWidth / 3 - 15
               ]
        )
        (Element.column [ Element.spacing smallSpace ]
            [ Element.text <| date
            , Element.paragraph [] [ Element.text lesson.thisfocus ]
            , Element.wrappedRow [ Element.alignBottom, Element.spacing smallSpace ]
                [ buttonElement "View" (GotoPageLesson lessonId)
                , buttonElement "Copy" (CopyLesson lessonId)
                , buttonElement "Edit"
                    (GotoPageEditLesson
                        { pupilId = pupilId
                        , dateString = date
                        , lesson = lesson
                        , oldDate = date
                        }
                    )
                , buttonElement "Delete" (DeleteLesson lessonId)
                ]
            ]
        )


headerElement statusText =
    Element.column
        [ Element.spacing bigSpace
        , Element.centerX
        ]
        [ Element.el
            [ Element.padding bigSpace ]
            (Input.button
                [ Element.padding bigSpace
                , Font.size 30
                , bgRed
                , fgWhite
                , roundedBorder
                ]
                { onPress = Just GotoPagePupils
                , label =
                    Element.el []
                        (Element.text "Lesson Journal")
                }
            )
        , Element.el
            [ Element.centerX ]
            (Element.text statusText)
        ]


pupilsPageElement : PupilLookup -> Element Msg
pupilsPageElement pupils =
    let
        pupilNames =
            Dict.keys pupils
    in
    Element.column
        [ Element.padding bigSpace, Element.centerX ]
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
        ]
        (Input.button
            [ Element.padding smallSpace
            ]
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


fgGray =
    Font.color (Element.rgb255 100 100 100)


bgRed =
    Background.color (Element.rgb255 140 10 10)


fgWhite =
    Font.color (Element.rgb255 255 255 255)


lightBorder =
    [ Border.width 1
    , Border.rounded 3
    , Border.color <| Element.rgb255 199 199 199
    , Element.padding 9
    ]


smallSpace =
    20


bigSpace =
    40


roundedBorder =
    Border.rounded 10


containerWidth =
    1000



-- @remind move view functions with friends to View.elm?
--  would possibly need to move Model there too, or 4th module Model
