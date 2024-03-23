PACT:=pact

all: check_types test 

test:
	pact test-bro-registry.repl
	pact test-bro-token.repl
	pact test-bro-pre-sales.repl
	pact test-bro-pre-sales-full-scenario.repl
	pact test-bro-token-treasury.repl

check_types:
	pact check_types.repl 2>&1 | grep -v kadenaswap
