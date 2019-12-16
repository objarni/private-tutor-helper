.PHONY: run
run:
	echo Not yet implemented

PHONY: build
build: output/index.html output/js/app.js
	echo Building...

output/index.html: index.html
	cp index.html output

output/js/app.js: src/Main.elm
	elm make src/Main.elm --output=output/js/app.js

