#!/usr/bin/env stack
-- stack script --resolver lts-11.22

import Development.Shake
import Development.Shake.FilePath

main = shakeArgs shakeOptions $ do
    want ["output/server.py"
         ,"output/bottle.py"
         ,"output/index.html"
         ,"output/js/app.js"]

    "output/*.py" %> \out -> do
        let src = replaceDirectory out "src"
        need [src]
        cmd "cp" [src] "output"

    "output/index.html" %> \out -> do
        need ["src/index.html"]
        cmd "cp src/index.html output"

    "output/js/app.js" %> \out -> do
        need ["src/Main.elm", "src/Pupil.elm"]
        cmd "elm make src/Main.elm" ["--output=" ++ out]

    phony "clean" $ do
        -- cmd "rm -rf output/"
        let toRemove = [".shake/", 
                        "elm-stuff/"]
        cmd "rm -rf" toRemove

-- output/js/app.js: src/*.elm
--     elm make src/Main.elm --output=output/js/app.js
