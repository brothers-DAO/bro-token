.PHONY: clean all init pact yaml rotate

#mainnet
NAMESPACE = "n_582fed11af00dc626812cd7890bb88e72067f28c"
DEX_NAMESPACE = "kaddex"
DATA_FILE = mainnet.yaml

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

init: tx_init_main_chain.yaml tx_init_0.yaml


JSON_TX = $(addprefix tx_, $(addsuffix .json, ${TRANSACTION_FILES}))
PACT_DATA = $(addprefix .pact/, $(addsuffix .pact, ${TRANSACTION_FILES}))
YAML_TX = $(addprefix tx_, $(addsuffix .yaml, ${TRANSACTION_FILES}))


pact: ${PACT_DATA}

yaml: ${YAML_TX} tx_launch.yaml

tx_launch.yaml: tkpl/launch.tkpl
	kda gen -t $< -d ${DATA_FILE} -o $@

tx_init_main_chain.yaml: tkpl/init_main_chain.tkpl
	kda gen -t $< -d ${DATA_FILE} -o $@

tx_init_0.yaml: tkpl/init_others_chains.tkpl
	kda gen -t $< -d ${DATA_FILE} -o tx_init_{{chain-other}}.yaml

rotate: tkpl/rotate.tkpl
	kda gen -t $< -d ${DATA_FILE} -o tx_rotate_{{chain}}.yaml

.pact:
	mkdir -p .pact

.pact/%.pact: pact_templates/%.m4 | .pact
	m4 -I../pact -DBRO_NS=${NAMESPACE} -DDEX_NS=${DEX_NAMESPACE} ${INIT} ${IS_INIT_CHAIN} $< > $@

tx_%.yaml: tkpl/%.tkpl .pact/%.pact ${DATA_FILE}
	kda gen -t $< -d ${DATA_FILE} -o $@

clean:
	rm -f ${PACT_DATA}
	rm -f tx_*.yaml
	rm -f tx_*.json
	rm -rf .pact
