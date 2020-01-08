.PHONY: run
run:
	cd output && python3.6 server.py

output:
	mkdir output

PHONY: build
build: output output/index.html output/js/app.js output/bottle.py output/server.py
	echo Building...

PHONY: clean
clean:
	$(RM) output/
	$(RM) elm-stuff/

output/js/app.js: src/*.elm
	elm make src/Main.elm --output=output/js/app.js

output/index.html: src/index.html
	cp src/index.html output

output/bottle.py: src/bottle.py
	cp src/bottle.py output

output/server.py: src/server.py
	cp src/server.py output
