module Main exposing (main, myElement, myRowOfStuff)

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
    el
        [ bg
        , fg
        , Border.rounded 3
        , padding 30
        ]
        (text "Hello world")


bg =
    Background.color (rgb255 0 140 165)


fg =
    Font.color (rgb255 255 255 255)
