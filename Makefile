.PHONY: build
build:
	python3 build.py

.PHONY: clean
clean:
	rm -rf output/

.PHONY: run
run:
	cd output && python3 server.py

.PHONY: lci
lci:
	ls src/* | entr sh -c 'clear && unbuffer python3 build.py 2>&1 | head --lines=25'

.PHONY: test
test:
	elm-test
