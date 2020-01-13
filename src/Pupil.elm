module Pupil exposing
    ( DateString
    , Lesson
    , Pupil
    , PupilId
    , pupilsFromJSON
    , pupilsToJSONString
    , replacePupil
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


type alias Lesson =
    { thisfocus : String
    , location : String
    , homework : String
    , nextfocus : String
    }



-- Decoders (JSON -> type)


pupilsFromJSON : D.Decoder (Dict PupilId Pupil)
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


pupilsToJSONString : Dict PupilId Pupil -> String
pupilsToJSONString savePupils =
    E.encode 2 <| pupilsToJSON savePupils


pupilsToJSON : Dict PupilId Pupil -> E.Value
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


replacePupil : Dict PupilId Pupil -> PupilId -> Pupil -> Dict PupilId Pupil
replacePupil pupils pupilId newPupil =
    let
        updatePupil pupil =
            Just newPupil
    in
    Dict.update pupilId updatePupil pupils
