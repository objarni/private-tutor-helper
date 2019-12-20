module Main exposing (main)

import Browser exposing (element)
import Element
    exposing
        ( Element
        , alignRight
        , centerX
        , centerY
        , column
        , el
        , fill
        , padding
        , rgb255
        , row
        , spacing
        , text
        , width
        , wrappedRow
        )
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Html exposing (Html)
import Json.Decode as D


main : Html msg
main =
    Element.layout []
        mainColumn


mainColumn : Element msg
mainColumn =
    column [ centerX, spacing bigSpace ]
        [ header, content ]


header =
    el
        [ bgBlue
        , fgWhite
        , roundedBorder
        , padding bigSpace
        , centerX
        ]
        (text "Lesson Journal")


content : Element msg
content =
    let
        result =
            D.decodeString modelDecoder jsonExample
    in
    case result of
        Ok pupils ->
            wrappedRow [ spacing smallSpace ]
                (List.map (\txt -> pupilButton txt) pupils)

        _ ->
            el
                [ bgRed
                , fgWhite
                , roundedBorder
                , padding smallSpace
                ]
                (text "Error in JSON!")


pupilButton : String -> Element a
pupilButton txt =
    el
        [ bgBlue
        , fgWhite
        , roundedBorder
        , padding smallSpace
        ]
        (text txt)


jsonExample =
    """
{
  "Pupils": [ "Alex", "Bertha", "Cecil" ]
}
"""


type alias Model =
    List String


modelDecoder : D.Decoder (List String)
modelDecoder =
    D.field "Pupils" (D.list D.string)


bgBlue =
    Background.color (rgb255 0 140 165)


bgRed =
    Background.color (rgb255 140 10 10)


fgWhite =
    Font.color (rgb255 255 255 255)


smallSpace =
    20


bigSpace =
    40


roundedBorder =
    Border.rounded 10
