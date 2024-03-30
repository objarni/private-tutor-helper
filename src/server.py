# coding: utf-8
import os
import time
import bottle

JOURNAL_PATH = "journal.json"
SLOWDOWN = 0.1

static_paths = [
    "js/app.js",
    "index.html",
    JOURNAL_PATH,
]


@bottle.route(f"/{JOURNAL_PATH}")
def load():
    print("Loading journal!")
    response = bottle.static_file(JOURNAL_PATH, "..")
    response.set_header("Cache-Control", "public, max-age=5")
    return response


@bottle.route("/save", method="POST")
def save():
    print("Saving journal!")
    with open(f"../{JOURNAL_PATH}", "wb") as f:
        time.sleep(SLOWDOWN)
        content = bottle.request.body.read()
        f.write(content)
    return "SUCCESS"


@bottle.route("/<path:re:.*>")
def path(path):
    print("GET", path)
    if path in static_paths:
        print("Current work directory: ", os.getcwd())
        time.sleep(SLOWDOWN)
        response = bottle.static_file(path, ".")
        # print("First part of response: ", response.body[:100])
        response.set_header("Cache-Control", "public, max-age=5")
        return response
    else:
        return "Unknown path"


@bottle.route("/")
def root():
    bottle.redirect("/index.html")


bottle.run(
    reloader=True, host="0.0.0.0", port=8000,
)
