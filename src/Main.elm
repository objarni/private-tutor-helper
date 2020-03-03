module Main exposing (main)

import Browser exposing (sandbox)
import Date
import Dict exposing (Dict)
import Element exposing (Element)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Html exposing (Html)
import Html.Events
import Http
import Mailto
import Pupil exposing (..)
import Set exposing (Set)
import Tagged
import Tagged.Dict


type alias Model =
    { pupils : PupilLookup
    , statusText : String
    , page : Page
    , saving : Bool
    , todaysDate : String
    }


type Page
    = PageMain
    | PageAddPupil AddPupilData
    | PagePupil PupilId
    | PageLesson LessonId
    | PageEditLesson EditLessonData
    | PageEditPupil EditPupilData


type alias AddPupilData =
    { nameError : Maybe String
    , name : String
    }



-- Msg name conventions
-- GotoXYZ --> a navigation message, switching page
-- Got/PutZYZ --> JSON response messages


type Msg
    = GotPupils (Result Http.Error PupilLookup)
    | PutPupils (Result Http.Error String)
    | Goto Page (Maybe String)
    | CopyLesson LessonId
    | DeleteLesson LessonId
    | CreatePupil PupilId
    | SuggestNewPupilName String
    | SaveLesson EditLessonData
    | DecrementDate
    | IncrementDate
    | SavePupil EditPupilData



-- @remind IDEA: LessonMsg EditLessonData LessonMsgKind ??


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
    ( { pupils = Tagged.Dict.empty
      , statusText = "Loading..."
      , page = PageMain
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

        Goto page maybeStatusText ->
            case maybeStatusText of
                Just text ->
                    ( { model | page = page, statusText = text }
                    , Cmd.none
                    )

                Nothing ->
                    ( { model | page = page }
                    , Cmd.none
                    )

        CopyLesson lessonId ->
            let
                newPupils =
                    opCopyLesson lessonId model.todaysDate model.pupils
            in
            savePupilsUpdate newPupils model.todaysDate "Lesson copied" (PagePupil lessonId.pupilId)

        DeleteLesson lessonId ->
            let
                newPupils =
                    opDeleteLesson lessonId model.pupils
            in
            savePupilsUpdate newPupils model.todaysDate "Lesson deleted" (PagePupil lessonId.pupilId)

        PutPupils _ ->
            ( { model
                | saving = False
                , statusText = "Journal saved."
              }
            , Cmd.none
            )

        SuggestNewPupilName name ->
            let
                nameError =
                    validatePupilId (Tagged.tag name) model
            in
            ( { model
                | page =
                    PageAddPupil
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
            savePupilsUpdate newPupils model.todaysDate "New pupil added" PageMain

        SaveLesson editLessonData ->
            let
                newPupils =
                    opUpdateLesson editLessonData model.pupils

                text =
                    "Saving lesson "
                        ++ editLessonData.newDate
                        ++ " of "
                        ++ Tagged.untag editLessonData.pupilId
                        ++ "..."
            in
            savePupilsUpdate newPupils model.todaysDate text (PagePupil editLessonData.pupilId)

        DecrementDate ->
            modifyNewLessonDateUpdate -1 model

        IncrementDate ->
            modifyNewLessonDateUpdate 1 model

        SavePupil pageData ->
            let
                newPupils =
                    opUpdatePupil pageData model.pupils

                text =
                    "Saving pupil "
                        ++ Tagged.untag pageData.pupilId
                        ++ "..."
            in
            savePupilsUpdate newPupils
                model.todaysDate
                text
                (PagePupil pageData.pupilId)


modifyNewLessonDateUpdate : Int -> Model -> ( Model, Cmd a )
modifyNewLessonDateUpdate direction model =
    let
        lessonData =
            case model.page of
                PageEditLesson editPageData ->
                    editPageData

                _ ->
                    Debug.todo "err"

        newDate =
            lessonData.newDate

        updatedDate =
            case Date.fromIsoString newDate of
                Ok date ->
                    Date.toIsoString (Date.add Date.Days direction date)

                Err error ->
                    error
    in
    ( { model
        | page = PageEditLesson { lessonData | newDate = updatedDate }
      }
    , Cmd.none
    )


gotPupilsUpdate model httpResult =
    case httpResult of
        Err (Http.BadBody s) ->
            mainModel model (Just ("Http error: " ++ s))

        Err _ ->
            mainModel model (Just "Http error")

        Ok loadedPupils ->
            -- for debugging purposes ability to jump to specific page state
            if True then
                mainModel
                    { model
                        | pupils = loadedPupils
                    }
                    (Just "Pupils loaded")

            else
                { model
                    | pupils = loadedPupils
                    , page = PagePupil (Tagged.tag "Bertha Babbage")
                    , statusText = "Debug landing page"
                }



-- @reminder: does not need whole Model, only pupil ids!


validatePupilId : PupilId -> Model -> Maybe String
validatePupilId pupilId model =
    let
        name =
            Tagged.untag pupilId

        notEmpty : String -> Bool
        notEmpty =
            not << String.isEmpty

        unique : String -> Bool
        unique id =
            -- @remind - get rid of lookupXX functions!
            case Tagged.Dict.get pupilId model.pupils of
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


savePupilsUpdate : PupilLookup -> DateString -> String -> Page -> ( Model, Cmd Msg )
savePupilsUpdate pupils today text nextPage =
    ( { pupils = pupils
      , saving = True
      , statusText = text
      , page = nextPage
      , todaysDate = today
      }
    , Http.post
        { url = "/save"
        , body = Http.stringBody "application/json" <| pupilsToJSONString pupils
        , expect = Http.expectString PutPupils
        }
    )



-- @remind do we really need this function anymore? Isn't pupilId included in page's
-- data if it is relevant, hence available where needed?


findSelectedPupilId : Model -> PupilId
findSelectedPupilId { pupils, page } =
    case page of
        PageMain ->
            Tagged.tag ""

        PageAddPupil _ ->
            Tagged.tag ""

        PagePupil pupilId ->
            pupilId

        PageLesson { pupilId } ->
            pupilId

        PageEditLesson { pupilId } ->
            pupilId

        PageEditPupil { pupilId } ->
            pupilId


mainModel : Model -> Maybe String -> Model
mainModel model maybeText =
    case maybeText of
        Just text ->
            { model
                | page = PageMain
                , statusText = text
            }

        Nothing ->
            { model
                | page = PageMain
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
            (subtleTextElement savingText)
        ]
        (viewElement model)


viewElement : Model -> Element Msg
viewElement model =
    let
        content =
            case model.page of
                PageMain ->
                    pupilsPageElement model.pupils

                PageAddPupil pageData ->
                    addPupilPageElement pageData

                PagePupil pupilId ->
                    case lookupPupil pupilId model of
                        Just p ->
                            pupilPageElement model.todaysDate pupilId p

                        Nothing ->
                            Debug.todo "Ugh"

                PageLesson lessonId ->
                    case
                        ( lookupPupil lessonId.pupilId model
                        , lookupLesson lessonId model
                        )
                    of
                        ( Just pupil, Just lesson ) ->
                            lessonPageElement pupil.email lessonId.date lesson

                        ( _, _ ) ->
                            Element.text "Huh?"

                PageEditLesson editLessonData ->
                    editLessonPageElement editLessonData

                PageEditPupil editPupilData ->
                    editPupilPageElement editPupilData
    in
    Element.column
        [ Element.centerX
        , Element.spacing bigSpace
        , Element.width (Element.maximum containerWidth Element.fill)
        ]
        [ headerElement model.statusText

        --, Element.text <| String.fromInt <| 4 * (1000 + 1850 + 5 * 300 + 12 * 1000)
        , content
        ]


type alias LessonProperty =
    { field : String
    , value : String
    }


lessonPageElement : Email -> DateString -> Lesson -> Element Msg
lessonPageElement email date lesson =
    let
        subject =
            "Summary of lesson " ++ date

        body =
            "This lesson: "
                ++ lesson.thisfocus
                ++ "\nHomework: "
                ++ lesson.homework
                ++ "\nNext lesson: "
                ++ lesson.nextfocus

        mailToAttr =
            Mailto.toHref
                (Mailto.mailto (Tagged.untag email)
                    |> Mailto.subject subject
                    |> Mailto.body body
                )

        mailtoLink =
            Element.el [ Element.centerX, Element.padding smallSpace ]
                (Element.html
                    (Html.a [ mailToAttr ] [ Html.text "Write mail summary" ])
                )

        para s =
            Element.paragraph [] [ Element.text s ]
    in
    Element.column [ Element.centerX ]
        [ Element.column (lightBorder ++ [ Element.spacing smallSpace, Element.centerX ])
            [ para <| "This lesson: " ++ lesson.thisfocus
            , para <| "Homework: " ++ lesson.homework
            , para <| "Next lesson: " ++ lesson.nextfocus
            ]
        , mailtoLink
        ]


editLessonPageElement : EditLessonData -> Element Msg
editLessonPageElement pageData =
    let
        { lesson } =
            pageData

        pageWidth =
            round (containerWidth / 2)

        dateIsFree =
            not (Set.member pageData.newDate pageData.otherLessonDates)

        fieldInput : String -> String -> (String -> Lesson) -> Element Msg
        fieldInput fieldName fieldValue modifyLesson =
            Input.multiline [ Element.width <| Element.px pageWidth ]
                { text = fieldValue
                , placeholder = Nothing
                , spellcheck = True
                , label = Input.labelAbove [] (Element.text fieldName)
                , onChange =
                    \x ->
                        Goto
                            (PageEditLesson
                                { pageData
                                    | lesson = modifyLesson x
                                }
                            )
                            Nothing
                }
    in
    Element.column
        [ Element.centerX
        , Element.spacing smallSpace
        , Element.padding bigSpace
        ]
        [ Element.text "Date"
        , let
            dateText =
                if dateIsFree then
                    "Date is free"

                else
                    "Cannot save - date occupied"

            duplicateDateElement =
                subtleTextElement dateText
          in
          Element.column (lightBorder ++ [ Element.width <| Element.px pageWidth ])
            [ Element.row [ Element.spacing smallSpace ]
                [ Element.text pageData.newDate
                , buttonElement "<" DecrementDate
                , buttonElement ">" IncrementDate
                ]
            , duplicateDateElement
            ]
        , fieldInput
            "Focus"
            lesson.thisfocus
            (\x -> { lesson | thisfocus = x })
        , fieldInput "Next focus" lesson.nextfocus (\x -> { lesson | nextfocus = x })
        , fieldInput "Homework" lesson.homework (\x -> { lesson | homework = x })
        , Element.el [ Element.centerX ]
            (if dateIsFree then
                buttonElement "Save" (SaveLesson pageData)

             else
                disabledButtonElement "Save"
            )
        ]


editPupilPageElement : EditPupilData -> Element Msg
editPupilPageElement pageData =
    let
        { pupil } =
            pageData

        pageWidth =
            round (containerWidth / 2)

        fieldInput : String -> String -> (String -> Pupil) -> Element Msg
        fieldInput fieldName fieldValue modifyPupil =
            Input.multiline [ Element.width <| Element.px pageWidth ]
                { text = fieldValue
                , placeholder = Nothing
                , spellcheck = True
                , label = Input.labelAbove [] (Element.text fieldName)
                , onChange =
                    \x ->
                        Goto
                            (PageEditPupil { pageData | pupil = modifyPupil x })
                            Nothing
                }
    in
    Element.column
        [ Element.centerX
        , Element.spacing smallSpace
        , Element.padding bigSpace
        ]
        [ fieldInput
            "Title"
            (Tagged.untag pupil.title)
            (\x -> { pupil | title = title x })
        , fieldInput
            "Email"
            (Tagged.untag pupil.email)
            (\x -> { pupil | email = email x })
        , Element.el [ Element.centerX ]
            (buttonElement
                "Save"
                (SavePupil pageData)
            )
        ]


addPupilPageElement : AddPupilData -> Element Msg
addPupilPageElement pageData =
    let
        button =
            case pageData.nameError of
                Nothing ->
                    buttonElement "Save" <| CreatePupil (Tagged.tag pageData.name)

                Just error ->
                    disabledButtonElement "Save"
    in
    Element.column [ Element.centerX ]
        [ Input.text []
            { onChange = \name -> SuggestNewPupilName name
            , text = pageData.name
            , placeholder = Nothing
            , label = Input.labelAbove [] (Element.text "Pupil name")
            }
        , subtleTextElement
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
    -- @remind remove this function ?
    Tagged.Dict.get pupilName pupils


lookupLesson : LessonId -> Model -> Maybe Lesson
lookupLesson { pupilId, date } { pupils } =
    let
        maybeRightPupil =
            Tagged.Dict.get pupilId pupils

        maybeLesson =
            case maybeRightPupil of
                Nothing ->
                    Nothing

                Just pupil ->
                    Dict.get date pupil.journal
    in
    maybeLesson


pupilPageElement : DateString -> PupilId -> Pupil -> Element Msg
pupilPageElement todaysDate pupilId ({ title, email, journal } as pupil) =
    let
        pupilName =
            Tagged.untag pupilId
    in
    Element.column
        [ Element.centerX
        , Element.spacing bigSpace
        ]
        [ Element.el [ Element.centerX ]
            (Element.text <| "Title: " ++ Tagged.untag title)
        , Element.el [ Element.centerX ]
            (Element.text <| "Email: " ++ Tagged.untag email)
        , Element.el [ Element.centerX ]
            (buttonElement "Edit"
                (Goto
                    (PageEditPupil { pupil = pupil, pupilId = pupilId })
                    (Just ("Editing " ++ pupilName))
                )
            )
        , lessonsElement todaysDate journal pupilId
        ]


lessonsElement : DateString -> Journal -> PupilId -> Element Msg
lessonsElement todaysDate lessons pupilId =
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
            (\( d, l ) -> lessonMasterElement todaysDate pupilId lessons l d)
            sortedLessonTuples
        )


lessonMasterElement : DateString -> PupilId -> Journal -> Lesson -> DateString -> Element Msg
lessonMasterElement todaysDate pupilId journal lesson lessonDate =
    let
        lessonText : Lesson -> String
        lessonText { thisfocus } =
            String.slice 0 115 thisfocus ++ ".."

        onlyLessonOfPupil =
            List.length (Dict.keys journal) == 1

        hasLessonWithTodaysDate =
            List.member todaysDate (Dict.keys journal)

        lessonId =
            { pupilId = pupilId
            , date = lessonDate
            }

        gotoMsg =
            Goto (PageLesson lessonId)
                (Just ("Lesson for " ++ Tagged.untag pupilId ++ " at " ++ lessonDate))
    in
    Element.el
        (lightBorder
            ++ [ Element.height <| Element.px 350
               , Element.width <| Element.px <| round <| containerWidth / 3 - 15
               ]
        )
        (Element.column [ Element.spacing smallSpace ]
            [ Element.text <| lessonDate
            , Element.paragraph [] [ Element.text (lessonText lesson) ]
            , Element.wrappedRow [ Element.alignBottom, Element.spacing smallSpace ]
                [ buttonElement "View" gotoMsg
                , if not hasLessonWithTodaysDate then
                    buttonElement "Copy" (CopyLesson lessonId)

                  else
                    disabledButtonElement "Copy"
                , buttonElement "Edit"
                    (Goto
                        (PageEditLesson
                            { pupilId = pupilId
                            , newDate = lessonDate
                            , lesson = lesson
                            , oldDate = lessonDate
                            , otherLessonDates = opAllLessonsExcept journal lessonDate
                            }
                        )
                        (Just <| "Editing " ++ lessonDate ++ " of " ++ Tagged.untag pupilId)
                    )
                , if onlyLessonOfPupil then
                    disabledButtonElement "Delete"

                  else
                    buttonElement "Delete" (DeleteLesson lessonId)
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
                { onPress = Just (Goto PageMain (Just "Viewing pupils"))
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
            Tagged.Dict.untaggedKeys pupils
    in
    Element.column
        [ Element.padding bigSpace, Element.centerX ]
        [ Element.wrappedRow
            [ Element.spacing smallSpace
            , Element.centerX
            ]
            (List.map (\name -> pupilButtonElement name) pupilNames)
        , Element.el [ Element.centerX, Element.padding bigSpace ]
            (buttonElement "Add Pupil"
                (Goto
                    (PageAddPupil
                        { nameError = Just "Name is empty"
                        , name = ""
                        }
                    )
                    (Just "Add new pupil")
                )
            )
        ]


pupilButtonElement pupil =
    buttonElement pupil
        (Goto
            (PagePupil <| Tagged.tag pupil)
            (Just ("Viewing " ++ pupil))
        )



-- Utility functions


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


subtleTextElement text =
    Element.el [ fgGray, Font.italic ]
        (Element.text text)


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
