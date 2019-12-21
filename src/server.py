# coding: utf-8
from bottle import debug, route, run, template, static_file


static_paths = ["js/app.js", "index.html", "journal.json"]


@route("/<path:re:.*>")
def path(path):
    if path in static_paths:
        return static_file(path, ".")
    else:
        return "Unknown path"


run(
    reloader=True, host="localhost", port=8000,
)
