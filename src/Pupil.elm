module Pupil exposing
    ( DateString
    , EditLessonData
    , EditPupilData
    , Journal
    , Lesson
    , LessonId
    , Pupil
    , PupilId
    , PupilLookup
    , opAllLessonsExcept
    , opCopyLesson
    , opCreatePupil
    , opDeleteLesson
    , opUpdateLesson
    , opUpdatePupil
    , pupilsFromJSON
    , pupilsToJSONString
    )

import Dict exposing (Dict)
import Json.Decode as D
import Json.Encode as E
import Set exposing (Set)


type alias PupilId =
    String


type alias DateString =
    String


type alias LessonId =
    { pupilId : String
    , date : String
    }


type alias Pupil =
    { title : String
    , email : String
    , journal : Journal
    }


type alias PupilLookup =
    Dict PupilId Pupil


type alias Journal =
    Dict DateString Lesson


type alias Lesson =
    { thisfocus : String
    , location : String
    , homework : String
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
    }


type alias EditPupilData =
    { pupilId : PupilId
    , pupil : Pupil
    }



-- Decoders (JSON -> type)


pupilsFromJSON : D.Decoder PupilLookup
pupilsFromJSON =
    D.field "Pupils"
        (D.dict pupilFromJSON)


pupilFromJSON : D.Decoder Pupil
pupilFromJSON =
    D.map3 Pupil
        (D.field "Email" D.string)
        (D.field "Title" D.string)
        (D.field "Journal"
            (D.dict
                lessonFromJSON
            )
        )


lessonFromJSON =
    D.map4 Lesson
        (D.field "ThisFocus" D.string)
        (D.field "Location" D.string)
        (D.field "Homework" D.string)
        (D.field "NextFocus" D.string)



-- Encoders (type -> JSON)


pupilsToJSONString : PupilLookup -> String
pupilsToJSONString savePupils =
    E.encode 2 <| pupilsToJSON savePupils


pupilsToJSON : PupilLookup -> E.Value
pupilsToJSON pupils =
    E.object
        [ ( "Pupils", E.dict identity pupilToJSON pupils )
        ]


pupilToJSON : Pupil -> E.Value
pupilToJSON pupil =
    E.object
        [ ( "Title", E.string pupil.title )
        , ( "Email", E.string pupil.email )
        , ( "Journal", E.dict identity lessonToJSON pupil.journal )
        ]


lessonToJSON : Lesson -> E.Value
lessonToJSON lesson =
    E.object
        [ ( "ThisFocus", E.string lesson.thisfocus )
        , ( "Location", E.string lesson.location )
        , ( "Homework", E.string lesson.homework )
        , ( "NextFocus", E.string lesson.nextfocus )
        ]



-- Operations


opCreatePupil : PupilId -> DateString -> PupilLookup -> PupilLookup
opCreatePupil pupilId date pupils =
    let
        insertLesson _ =
            Just
                { thisfocus = "Learn stuff"
                , nextfocus = "Learn more stuff"
                , homework = "Practice, practice, practice"
                , location = "Remote"
                }

        newJournal =
            Dict.update date insertLesson Dict.empty

        newPupil =
            { title = "Mr Pupil"
            , email = "first.last@anywhere.co.uk"
            , journal = newJournal
            }
    in
    Dict.update pupilId (\_ -> Just newPupil) pupils



-- @remind should be working on Journal, not PupilLookup!


opUpdateLesson : EditLessonData -> PupilLookup -> PupilLookup
opUpdateLesson { pupilId, newDate, lesson, oldDate } pupils =
    case Dict.get pupilId pupils of
        Just pupil ->
            let
                journalWithoutOldLesson =
                    Dict.remove oldDate pupil.journal

                newJournal =
                    Dict.update newDate (\_ -> Just lesson) journalWithoutOldLesson

                updatedPupil =
                    { pupil | journal = newJournal }
            in
            Dict.update pupilId (\_ -> Just updatedPupil) pupils

        Nothing ->
            -- @remind this feels wrong
            pupils


opUpdatePupil : EditPupilData -> PupilLookup -> PupilLookup
opUpdatePupil { pupilId, pupil } pupils =
    Dict.update pupilId (\_ -> Just pupil) pupils



-- @remind use Journal not PupilLookup


opCopyLesson : LessonId -> DateString -> PupilLookup -> PupilLookup
opCopyLesson ({ pupilId, date } as lessonId) todaysDate pupils =
    case Dict.get pupilId pupils of
        Just pupil ->
            let
                oldLesson =
                    Dict.get date pupil.journal

                newJournal =
                    Dict.update todaysDate (\_ -> oldLesson) pupil.journal

                newPupil =
                    { pupil | journal = newJournal }
            in
            Dict.update pupilId (\_ -> Just newPupil) pupils

        Nothing ->
            pupils



-- @remind use Journal not PupilLookup


opDeleteLesson : LessonId -> PupilLookup -> PupilLookup
opDeleteLesson ({ pupilId, date } as lessonId) pupils =
    case Dict.get pupilId pupils of
        Just pupil ->
            let
                newPupil =
                    { pupil
                        | journal =
                            Dict.remove date pupil.journal
                    }
            in
            Dict.update pupilId (\_ -> Just newPupil) pupils

        Nothing ->
            pupils


opAllLessonsExcept : Journal -> DateString -> Set DateString
opAllLessonsExcept journal date =
    Set.fromList <| Dict.keys (Dict.remove date journal)
