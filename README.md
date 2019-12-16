# private-tutor-helper

Simple web app to help journalling lessons given while doing private tutoring

## Why?

I needed a way to keep track of what lessons I had given, e.g. their content, what "home work" I suggested, and what hurdles were observed, as a reminder to myself for the next lesson.

The previous iteration of this "system" was a single `journal.json` file structured so that I could easily add entries (and read previous entries).


## What technologies are used?

  - Elm0.19 + elm-ui for front end
  - Python3.6 with bottle.py for backend
  - git + GitHub for hosting, version control and CI
  - Make for building, testing, serving app


## How do I run the app?

    make build && make run


# How do I clean up?

    make clean
