module Main exposing (main)

import Browser exposing (sandbox)
import Element exposing (Element)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Html exposing (Html)
import Html.Events
import Http
import Json.Decode as D


main : Program () Model Msg
main =
    Browser.element
        { init = initialModel
        , update = update
        , view = view
        , subscriptions = subscriptions
        }


type alias Model =
    { pupils : List String
    , text : String
    }


type Msg
    = ClickMsg
    | GotJson (Result Http.Error (List String))


initialModel _ =
    ( { pupils = [ "Alex", "Bertha", "Cecil" ]
      , text = "No response yet"
      }
    , Cmd.none
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg { pupils, text } =
    case msg of
        ClickMsg ->
            ( { pupils = pupils ++ [ "Dolph" ]
              , text = "Added pupil"
              }
            , Http.get
                { url = "/journal.json"
                , expect = Http.expectJson GotJson jsonDecoder
                }
            )

        GotJson result ->
            case result of
                Err _ ->
                    ( { pupils = pupils, text = "Http error" }
                    , Cmd.none
                    )

                Ok newPupils ->
                    ( { pupils = newPupils, text = "Loaded" }
                    , Cmd.none
                    )


view model =
    Element.layout []
        (mainColumn model)


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none


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


jsonDecoder : D.Decoder (List String)
jsonDecoder =
    D.field "Pupils" (D.list (D.field "Name" D.string))


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
