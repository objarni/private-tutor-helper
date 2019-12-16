# coding: utf-8

from bottle import route, run, template

@route('/')
def index():
    return '<b>Hello world</b>!'

run(host='localhost', port=8000)

