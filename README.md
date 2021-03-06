# private-tutor-helper

Simple web app to help journalling lessons given while doing private tutoring.


## Why?

I needed a way to keep track of what lessons I had given, e.g. their content, what "home work" I suggested, and what hurdles were observed, as a reminder to myself for the next lesson.

The previous iteration of this system was a single `journal.json` file structured so that I could easily add entries (and read previous entries). An example of the content would be:

```
{
  "Pupils": {
    "Bill Klinton": {
      "Title": "CEO Digital Soft",
      "Email": "bill@klingon.net",
      "Journal": {
        "2019-12-01": {
          "Location": "At his home",
          "ThisFocus": "PyCharm+requests installation and testing AB/CD API",
          "Homework": "Finish script",
          "NextFocus": "String formatting"
        },
        "2019-12-15": {
          "Location": "At his home",
          "ThisFocus": "String formatting, especially f-strings",
          "Homework": "Rewrite string formatting code of script to use f-strings",
          "NextFocus": "Logging"
        }
      }
    }
  }
}
```

### How do I run the app?

    make build && make run

.. then surf to http://localhost:8000/index.html to view and update journal.


### What technologies are used?

  - Elm0.19 + elm-ui for front end
  - Python3.6 with bottle.py for backend
  - git + GitHub for hosting, version control and CI
  - Make for building, testing, serving app


### TODO

  - go back to makefile development workflow (remove Build.hs)
  - introduce elm-test to project (investigate how this is installed properly in 19.1 nowadays)
  - introduce elm-program-test for regression testing
