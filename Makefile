.PHONY: run
run:
	cd output && python3.6 server.py

.PHONY: lci
lci:
	ls src/* | entr sh -c 'clear && unbuffer ./Build.hs 2>&1 | head --lines=30'
