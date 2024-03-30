# private-tutor-helper

Simple web app to help journalling lessons given while doing private tutoring.


## Why?

I needed a way to keep track of what lessons I had given, e.g. their content, what "homework" I suggested, and what hurdles were observed, as a reminder to myself for the next lesson.

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

### How do I setup development environment?

Install elm:

    npm install -g elm

Also make sure Python3.6+ is available.


### How do I build the app?

    ./build.sh


### How do I run the app?

    ./run.sh

.. then surf to http://localhost:8000/index.html to view and update journal.


### What is the tech stack?

  - Elm0.19 + elm-ui for front end
  - Python3.6 with bottle.py for backend
  - git + GitHub for hosting, version control
  - Bash scripts for build, running


### TODO

  - introduce elm-test to project (investigate how this is installed properly in 19.1 nowadays)
  - introduce elm-program-test for regression testing
