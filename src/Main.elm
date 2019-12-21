module Main exposing (main)

import Browser exposing (sandbox)
import Element exposing (Element)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Html exposing (Html)
import Html.Events
import Json.Decode as D


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
    Element.column [ Element.centerX, Element.spacing bigSpace ]
        [ header, content model, footer model.text ]


footer txt =
    Element.el [ Element.centerX ] (Element.text txt)


header =
    Element.el
        [ bgBlue
        , fgWhite
        , roundedBorder
        , Element.padding bigSpace
        , Element.centerX
        ]
        (Element.text "Lesson Journal")


content : Model -> Element Msg
content model =
    Element.wrappedRow [ Element.spacing smallSpace ]
        (List.map (\txt -> pupilButton txt) model.pupils)


pupilButton : String -> Element Msg
pupilButton txt =
    Element.el
        [ bgBlue
        , fgWhite
        , roundedBorder
        , Element.padding smallSpace
        ]
        (Input.button []
            { onPress = Just ClickMsg
            , label = Element.text txt
            }
        )



--(Element.html
--    (Html.button [ Html.Events.onClick ClickMsg ]
--        [ Html.text txt ]
--    )
--)


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
    Background.color (Element.rgb255 0 140 165)


bgRed =
    Background.color (Element.rgb255 140 10 10)


fgWhite =
    Font.color (Element.rgb255 255 255 255)


smallSpace =
    20


bigSpace =
    40


roundedBorder =
    Border.rounded 10
