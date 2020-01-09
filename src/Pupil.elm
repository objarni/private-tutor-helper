module Pupil exposing
    ( Lesson
    , Pupil
    , PupilId
    , lessonFromJSON
    , pupilsFromJSON
    , pupilsToJSONString
    )

import Dict exposing (Dict)
import Json.Decode as D
import Json.Encode as E


type alias PupilId =
    String


type alias Pupil =
    { title : String
    , journal : List Lesson
    }


type alias Lesson =
    { date : String
    , thisfocus : String
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
            (D.list
                lessonFromJSON
            )
        )


lessonFromJSON =
    D.map5 Lesson
        (D.field "Date" D.string)
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
        , ( "Journal", E.list lessonToJSON pupil.journal )
        ]


lessonToJSON : Lesson -> E.Value
lessonToJSON lesson =
    E.object
        [ ( "Date", E.string lesson.date )
        , ( "ThisFocus", E.string lesson.thisfocus )
        , ( "Location", E.string lesson.location )
        , ( "Homework", E.string lesson.homework )
        , ( "NextFocus", E.string lesson.nextfocus )
        ]
