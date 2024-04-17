#mainnet
NAMESPACE = "n_5d119cc07ffd5efaef5c7feef9e878f34e3d4652"
DEX_NAMESPACE = "n_8e906b0c6bd3a01c2002dc06fcb2dbe2eb8afa76"
#DATA_FILE = mainnet_data.yaml
DATA_FILE = testnet.yaml

#Uncomment for first init
INIT=-D__INIT__

#Whether we are on the init chain
#IS_INIT_CHAIN=-D__IS_INIT_CHAIN__

TRANSACTION_FILES = bro-registry \
                    bro-token \
                    bro-pre-sales \
                    bro-treasury \
                    post-init


all: yaml

JSON_TX = $(addprefix tx_, $(addsuffix .json, ${TRANSACTION_FILES}))
PACT_DATA = $(addprefix .pact/, $(addsuffix .pact, ${TRANSACTION_FILES}))
YAML_TX = $(addprefix tx_, $(addsuffix .yaml, ${TRANSACTION_FILES}))

pact: ${PACT_DATA}

yaml: ${YAML_TX}

.pact:
	mkdir -p .pact

.pact/%.pact: pact_templates/%.m4 | .pact
	m4 -I../pact -DBRO_NS=${NAMESPACE} -DDEX_NS=${DEX_NAMESPACE} ${INIT} ${IS_INIT_CHAIN} $< > $@

tx_%.yaml: tkpl/%.tkpl .pact/%.pact ${DATA_FILE}
	kda gen -t $< -d ${DATA_FILE} -o $@

clean:
	rm -f ${PACT_DATA}
	rm -f ${JSON_TX}
	rm -f ${YAML_TX}
	rm -rf .pact
