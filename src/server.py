# coding: utf-8
from bottle import route, run, template, static_file


@route('/js/app.js')
def elm_app():
    return static_file('js/app.js', root='.')


@route('/')
def index():
    return static_file('index.html', root='.')


@route('/load.json')
def load_json():
    return static_file('journal.json', root='.')


run(host='localhost', port=8000)

