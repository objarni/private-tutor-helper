module Pupil exposing
    ( DateString
    , EditLessonData
    , EditPupilData
    , Email
    , Journal
    , Lesson
    , LessonId
    , Pupil
    , PupilId
    , PupilLookup
    , email
    , homework
    , opAllLessonsExcept
    , opCopyLesson
    , opCreatePupil
    , opDeleteLesson
    , opUpdateLesson
    , opUpdatePupil
    , pupilsFromJSON
    , pupilsToJSONString
    , thisFocus
    , title
    )

import Dict exposing (Dict)
import Json.Decode as D
import Json.Encode as E
import Set exposing (Set)
import Tagged exposing (Tagged)
import Tagged.Dict exposing (TaggedDict)


type alias PupilId =
    Tagged PupilIdTag String


type alias DateString =
    String


type alias LessonId =
    { pupilId : PupilId
    , date : String
    }



-- Tagged type Email


type EmailTag
    = EmailTag


type alias Email =
    Tagged.Tagged EmailTag String


email : String -> Email
email =
    Tagged.tag



-- Tagged type title


type TitleTag
    = TitleTag


type alias Title =
    Tagged.Tagged TitleTag String


title : String -> Title
title =
    Tagged.tag



-- Tagged type Homework


type HomeworkTag
    = HomeworkTag


type alias Homework =
    Tagged.Tagged HomeworkTag String


homework : String -> Homework
homework =
    Tagged.tag



-- Tagged type Location
-- @remind Location not used in UI - remove?


type LocationTag
    = LocationTag


type alias Location =
    Tagged.Tagged LocationTag String


location : String -> Location
location =
    Tagged.tag



-- Tagged type ThisFocus


type ThisFocusTag
    = ThisFocusTag


type alias ThisFocus =
    Tagged.Tagged ThisFocusTag String


thisFocus : String -> ThisFocus
thisFocus =
    Tagged.tag


type alias Pupil =
    { title : Title
    , email : Email
    , journal : Journal
    }


type alias Journal =
    Dict DateString Lesson


type alias Lesson =
    { thisfocus : ThisFocus
    , location : Location
    , homework : Homework
    , nextfocus : String
    }



-- @remind this record feels very 'far away' from
-- the JSON/pupils data -- better name or other design?


type alias EditLessonData =
    { pupilId : PupilId
    , newDate : DateString
    , lesson : Lesson
    , oldDate : DateString
    , otherLessonDates : Set DateString
    , confirmDeletePopup : Bool
    }


type alias EditPupilData =
    { pupilId : PupilId
    , pupil : Pupil
    }



-- Decoders (JSON -> type)


type PupilIdTag
    = PupilIdTag


type alias PupilLookup =
    TaggedDict PupilIdTag String Pupil


pupilsFromJSON : D.Decoder PupilLookup
pupilsFromJSON =
    D.field "Pupils"
        (D.keyValuePairs pupilFromJSON |> D.map Tagged.Dict.fromUntaggedList)


pupilFromJSON : D.Decoder Pupil
pupilFromJSON =
    D.map3 Pupil
        (D.field "Title" (D.map title D.string))
        (D.field "Email" (D.map email D.string))
        (D.field "Journal"
            (D.dict
                lessonFromJSON
            )
        )


lessonFromJSON =
    D.map4 Lesson
        (D.field "ThisFocus" (D.map thisFocus D.string))
        (D.field "Location" (D.map location D.string))
        (D.field "Homework" (D.map homework D.string))
        (D.field "NextFocus" D.string)



-- Encoders (type -> JSON)


pupilsToJSONString : PupilLookup -> String
pupilsToJSONString savePupils =
    E.encode 2 <| pupilsToJSON savePupils


pupilsToJSON : PupilLookup -> E.Value
pupilsToJSON pupils =
    let
        untaggedIds =
            Tagged.Dict.untaggedKeys pupils

        pupilsList =
            Tagged.Dict.values pupils

        pupilValues =
            List.map pupilToJSON pupilsList

        weave =
            List.map2 Tuple.pair untaggedIds pupilValues
    in
    E.object
        [ ( "Pupils", E.object weave )
        ]


pupilToJSON : Pupil -> E.Value
pupilToJSON pupil =
    E.object
        [ ( "Title", E.string (Tagged.untag pupil.title) )
        , ( "Email", E.string (Tagged.untag pupil.email) )
        , ( "Journal", E.dict identity lessonToJSON pupil.journal )
        ]


lessonToJSON : Lesson -> E.Value
lessonToJSON lesson =
    E.object
        [ ( "ThisFocus", E.string (Tagged.untag lesson.thisfocus) )
        , ( "Location", E.string (Tagged.untag lesson.location) )
        , ( "Homework", E.string (Tagged.untag lesson.homework) )
        , ( "NextFocus", E.string lesson.nextfocus )
        ]



-- Operations


opCreatePupil : PupilId -> DateString -> PupilLookup -> PupilLookup
opCreatePupil pupilId date pupils =
    let
        insertLesson _ =
            Just
                { thisfocus = thisFocus "Learn stuff"
                , nextfocus = "Learn more stuff"
                , homework = homework "Practice, practice, practice"
                , location = location "Remote"
                }

        newJournal =
            Dict.update date insertLesson Dict.empty

        newPupil =
            { title = title "Mr Pupil"
            , email = email "first.last@anywhere.co.uk"
            , journal = newJournal
            }
    in
    Tagged.Dict.update pupilId (\_ -> Just newPupil) pupils



-- @remind should be working on Journal, not PupilLookup!


opUpdateLesson : EditLessonData -> PupilLookup -> PupilLookup
opUpdateLesson { pupilId, newDate, lesson, oldDate } pupils =
    case Tagged.Dict.get pupilId pupils of
        Just pupil ->
            let
                journalWithoutOldLesson =
                    Dict.remove oldDate pupil.journal

                newJournal =
                    Dict.update newDate (\_ -> Just lesson) journalWithoutOldLesson

                updatedPupil =
                    { pupil | journal = newJournal }
            in
            Tagged.Dict.update pupilId (\_ -> Just updatedPupil) pupils

        Nothing ->
            -- @remind this feels wrong
            pupils


opUpdatePupil : EditPupilData -> PupilLookup -> PupilLookup
opUpdatePupil { pupilId, pupil } pupils =
    Tagged.Dict.update pupilId (\_ -> Just pupil) pupils



-- @remind use Journal not PupilLookup


opCopyLesson : LessonId -> DateString -> PupilLookup -> PupilLookup
opCopyLesson { pupilId, date } todaysDate pupils =
    case Tagged.Dict.get pupilId pupils of
        Just pupil ->
            let
                oldLesson =
                    Dict.get date pupil.journal

                newJournal =
                    Dict.update todaysDate (\_ -> oldLesson) pupil.journal

                newPupil =
                    { pupil | journal = newJournal }
            in
            Tagged.Dict.update pupilId (\_ -> Just newPupil) pupils

        Nothing ->
            pupils



-- @remind use Journal not PupilLookup


opDeleteLesson : LessonId -> PupilLookup -> PupilLookup
opDeleteLesson { pupilId, date } pupils =
    case Tagged.Dict.get pupilId pupils of
        Just pupil ->
            let
                newPupil =
                    { pupil
                        | journal =
                            Dict.remove date pupil.journal
                    }
            in
            Tagged.Dict.update pupilId (\_ -> Just newPupil) pupils

        Nothing ->
            pupils


opAllLessonsExcept : Journal -> DateString -> Set DateString
opAllLessonsExcept journal date =
    Set.fromList <| Dict.keys (Dict.remove date journal)
