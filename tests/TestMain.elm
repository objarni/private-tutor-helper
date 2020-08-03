module TestMain exposing (exampleProgramTest)

import Main
import ProgramTest
import Test exposing (..)
import Test.Html.Selector exposing (class, text)


exampleProgramTest : Test
exampleProgramTest =
    test "shows hello on screen" <|
        \() ->
            ProgramTest.createElement
                { init = Main.initialModel
                , update = Main.update
                , view = Main.view
                }
                |> ProgramTest.withSimulatedEffects
                |> ProgramTest.start "2020-01-02"
                |> ProgramTest.simulateHttpOk "GET"
                    "https://example.com/time.json"
                    """{"currentTime":1559013158}"""
                |> ProgramTest.expectViewHas
                    [ text
                        "hello"
                    ]
