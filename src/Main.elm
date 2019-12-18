module Main exposing (main, myElement, myRowOfStuff)

import Browser exposing (element)
import Element
    exposing
        ( Element
        , alignRight
        , centerX
        , centerY
        , el
        , fill
        , padding
        , rgb255
        , row
        , spacing
        , text
        , width
        )
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Html exposing (Html)
import Json.Decode as D


main : Html msg
main =
    Element.layout []
        myRowOfStuff


myRowOfStuff : Element msg
myRowOfStuff =
    row [ width fill, centerY, spacing 30 ]
        [ el [ centerX ] myElement
        ]


myElement : Element msg
myElement =
    let
        result =
            D.decodeString modelDecoder jsonExample
    in
    case result of
        Ok txt ->
            el
                [ bg
                , fg
                , Border.rounded 3
                , padding 30
                ]
                (text txt)

        _ ->
            el
                [ bg
                , fg
                , Border.rounded 3
                , padding 30
                ]
                (text "Error in JSON!")


jsonExample =
    "\"Hello World!\""


type alias Model =
    String


modelDecoder : D.Decoder Model
modelDecoder =
    D.string


bg =
    Background.color (rgb255 0 140 165)


fg =
    Font.color (rgb255 255 255 255)
