module Pupil exposing
    ( DateString
    , EditLessonData
    , Lesson
    , Pupil
    , PupilId
    , PupilLookup
    , createPupil
    , pupilsFromJSON
    , pupilsToJSONString
    , replacePupil
    , updateLesson
    )

import Dict exposing (Dict)
import Json.Decode as D
import Json.Encode as E


type alias PupilId =
    String


type alias DateString =
    String


type alias Pupil =
    { title : String
    , journal : Dict DateString Lesson
    }


type alias PupilLookup =
    Dict PupilId Pupil


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
    , dateString : DateString
    , lesson : Lesson
    , oldDate : DateString
    }



-- Decoders (JSON -> type)


pupilsFromJSON : D.Decoder PupilLookup
pupilsFromJSON =
    D.field "Pupils"
        (D.dict pupilFromJSON)


pupilFromJSON : D.Decoder Pupil
pupilFromJSON =
    D.map2 Pupil
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


replacePupil : PupilLookup -> PupilId -> Pupil -> PupilLookup
replacePupil pupils pupilId newPupil =
    let
        updatePupil pupil =
            Just newPupil
    in
    Dict.update pupilId updatePupil pupils


createPupil : PupilId -> DateString -> PupilLookup -> PupilLookup
createPupil pupilId date pupils =
    let
        insertLesson maybeLesson =
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
            , journal = newJournal
            }
    in
    Dict.update pupilId (\_ -> Just newPupil) pupils


updateLesson : EditLessonData -> PupilLookup -> PupilLookup
updateLesson { pupilId, dateString, lesson } pupils =
    case Dict.get pupilId pupils of
        Just oldPupil ->
            let
                updatedJournal =
                    Dict.update dateString (\_ -> Just lesson) oldPupil.journal

                updatedPupil =
                    { oldPupil | journal = updatedJournal }

                updatedPupils =
                    Dict.update pupilId (\_ -> Just updatedPupil) pupils
            in
            updatedPupils

        Nothing ->
            -- @remind this feels wrong
            pupils
