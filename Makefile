TOP_DIR = ../..
include $(TOP_DIR)/tools/Makefile.common

DEPLOY_RUNTIME ?= /kb/runtime
TARGET ?= /kb/deployment

SERVER_SPEC = protein_info.spec
SERVICE = protein_info_service
SERVICE_PORT = 7057

# MOD is the prefix of your automatically generated psgi file. It will always be 
# <Something>Service.
MOD = ProteinInfoService
LDIR = lib/Bio/KBase/$(MOD)
DEPS = $(LDIR)/Impl.pm $(LDIR)/Service.pm $(LDIR)/Client.pm

TPAGE_ARGS = --define kb_top=$(TARGET) --define kb_runtime=$(DEPLOY_RUNTIME) --define kb_service_name=$(SERVICE) \
	--define kb_service_port=$(SERVICE_PORT) \
	--define kb_mod=$(MOD)

all: $(DEPS) bin

deploy: $(DEPS) deploy-scripts deploy-libs deploy-service

deploy-service: deploy-dir-service deploy-services deploy-monit

$(DEPS): $(SERVER_SPEC)
	mkdir -p tscripts
	compile_typespec \
		--impl Bio::KBase::$(MOD)::Impl \
		--service Bio::KBase::$(MOD)::Service \
		--psgi $(MOD).psgi \
		--client Bio::KBase::$(MOD)::Client \
		--js $(MOD) \
		--scripts tscripts \
		$(SERVER_SPEC) \
		lib

bin: $(BIN_PERL)

deploy-services:
	$(TPAGE) $(TPAGE_ARGS) service/start_service.tt > $(TARGET)/services/$(SERVICE)/start_service
	chmod +x $(TARGET)/services/$(SERVICE)/start_service
	$(TPAGE) $(TPAGE_ARGS) service/stop_service.tt > $(TARGET)/services/$(SERVICE)/stop_service
	chmod +x $(TARGET)/services/$(SERVICE)/stop_service

deploy-monit:
	$(TPAGE) $(TPAGE_ARGS) service/process.$(SERVICE).tt > $(TARGET)/services/$(SERVICE)/process.$(SERVICE)


deploy-docs:
	if [ ! -d doc ] ; then mkdir doc ; fi
	$(KB_RUNTIME)/bin/pod2html -t $(MOD) lib/Bio/KBase/$(MOD)/Impl.pm > doc/$(MOD).html
	# cp doc/$(MOD).html to the docs repo and then commit but that's too much for now

include $(TOP_DIR)/tools/Makefile.common.rules

# You can change these if you are putting your tests somewhere
# else or if you are not using the standard .t suffix
CLIENT_TESTS = $(wildcard client-tests/*.t)
SCRIPTS_TESTS = $(wildcard script-tests/*.t)
SERVER_TESTS = $(wildcard server-tests/*.t)

# Test Section

test: test-client test-scripts
	echo "running client and script tests"

test-all: test-client test-scripts test-server

test-client:
	# run each test
	for t in $(CLIENT_TESTS) ; do \
		if [ -f $$t ] ; then \
			$(DEPLOY_RUNTIME)/bin/perl $$t ; \
			if [ $$? -ne 0 ] ; then \
				exit 1 ; \
			fi \
		fi \
	done

test-scripts:
	# run each test
	for t in $(SCRIPT_TESTS) ; do \
		if [ -f $$t ] ; then \
			$(DEPLOY_RUNTIME)/bin/perl $$t ; \
			if [ $$? -ne 0 ] ; then \
				exit 1 ; \
			fi \
		fi \
	done

test-server:
	# run each test
	for t in $(SERVER_TESTS) ; do \
		if [ -f $$t ] ; then \
			$(DEPLOY_RUNTIME)/bin/perl $$t ; \
			if [ $$? -ne 0 ] ; then \
				exit 1 ; \
			fi \
		fi \
	done

