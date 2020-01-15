# coding: utf-8
import time
import bottle

JOURNAL_PATH = "journal.json"
SLOWDOWN = 0.5

static_paths = [
    "js/app.js",
    "index.html",
    JOURNAL_PATH,
]


@bottle.route("/<path:re:.*>")
def path(path):
    if path in static_paths:
        time.sleep(SLOWDOWN)
        response = bottle.static_file(path, ".")
        response.set_header("Cache-Control", "public, max-age=5")
        return response
    else:
        return "Unknown path"


@bottle.route("/save", method="POST")
def save():
    with open(JOURNAL_PATH, "wb") as f:
        time.sleep(SLOWDOWN)
        content = bottle.request.body.read()
        f.write(content)
    return "SUCCESS"


@bottle.route("/")
def root():
    bottle.redirect("/index.html")


bottle.run(
    reloader=True, host="localhost", port=8000,
)
