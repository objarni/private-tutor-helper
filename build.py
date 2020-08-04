# private-tutor-helper build script

import shutil
import pathlib
import subprocess


def target_needs_update(sources, target):
    for source in sources:
        if not target.exists():
            return True
        if target.stat().st_mtime < source.stat().st_mtime:
            return True
    return False


def maybe_do(operation, sources, target):
    sources = [pathlib.Path(source) for source in sources]
    for source in sources:
        if not source.exists():
            print(f"Source does not exist: {source}, halt.")
            return
    target = pathlib.Path(target)
    if target_needs_update(sources, target):
        operation(sources, target)


def copy(sources, target):
    print(f"cp {sources} {target}")
    assert len(sources) == 1
    source = sources[0]
    pathlib.Path(target).parent.mkdir(parents=True, exist_ok=True)
    shutil.copy(source, target)


def elm(sources, target):
    print(f"elm {sources} {target}")
    subprocess.run(["unbuffer", "elm", "make", "src/Main.elm", f"--output={target}"])


# Idea: syntax similar to what would be written on
# command line to make everything manually
maybe_do(copy, ["src/index.html"], "output/index.html")
maybe_do(copy, ["src/server.py"], "output/server.py")
maybe_do(copy, ["src/bottle.py"], "output/bottle.py")
maybe_do(elm, ["src/Main.elm", "src/Pupil.elm"], "output/js/app.js")
"""
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
        cmd "unbuffer elm make src/Main.elm" ["--output=" ++ out]

    phony "clean" $ do
        -- cmd "rm -rf output/"
        let toRemove = [".shake/", 
                        "elm-stuff/"]
        cmd "rm -rf" toRemove

-- output/js/app.js: src/*.elm
--     elm make src/Main.elm --output=output/js/app.js
"""
