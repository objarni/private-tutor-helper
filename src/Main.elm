module Main exposing (main)

import Browser exposing (sandbox)
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
import Element.Input as Input
import Html exposing (Html)
import Html.Events
import Json.Decode as D



--main : Html Msg


main =
    Browser.sandbox
        { init = init
        , update = update
        , view = view
        }


init =
    { pupils = [ "Alex", "Bertha", "Cecil" ]
    , text = "No response yet"
    }


update : Msg -> Model -> Model
update ClickMsg { pupils, text } =
    { pupils = pupils ++ [ "Dolph" ]
    , text = text
    }


view model =
    Element.layout []
        (mainColumn model)


mainColumn : Model -> Element Msg
mainColumn model =
    column [ centerX, spacing bigSpace ]
        [ header, content model, footer model.text ]


footer txt =
    el [ centerX ] (text txt)


header =
    el
        [ bgBlue
        , fgWhite
        , roundedBorder
        , padding bigSpace
        , centerX
        ]
        (text "Lesson Journal")


content : Model -> Element Msg
content model =
    wrappedRow [ spacing smallSpace ]
        (List.map (\txt -> pupilButton txt) model.pupils)


pupilButton : String -> Element Msg
pupilButton txt =
    el
        [ bgBlue
        , fgWhite
        , roundedBorder
        , padding smallSpace
        ]
        (Element.html
            (Html.button [ Html.Events.onClick ClickMsg ] [ Html.text txt ])
        )



--Input.button
--    [ bgBlue
--    , fgWhite
--    , roundedBorder
--    , padding smallSpace
--    ]
--    { label = text txt
--    , onPress = Just ClickMsg
--    }


type Msg
    = ClickMsg


jsonExample =
    """
{
  "Pupils": [ "Alex", "Bertha", "Cecil" ]
}
"""


type alias Model =
    { pupils : List String
    , text : String
    }


jsonDecoder : D.Decoder (List String)
jsonDecoder =
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
