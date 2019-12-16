.PHONY: run
run:
	cd output && python3.6 server.py

PHONY: build
build: output/index.html output/js/app.js output/bottle.py output/server.py
	echo Building...

output/js/app.js: src/Main.elm
	elm make src/Main.elm --output=output/js/app.js

output/index.html: src/index.html
	cp index.html output

output/bottle.py: src/bottle.py
	cp src/bottle.py output

output/server.py: src/server.py
	cp src/server.py output
