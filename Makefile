# configurable variables 
# SERVICE is the git module name
SERVICE = protein_info_service
# SERVICE_NAME is the name of the language libs
SERVICE_NAME = ProteinInfoService
SERVICE_PSGI_FILE = ProteinInfoService.psgi
SERVICE_PORT = 7057

#standalone variables which are replaced when run via /kb/dev_container/Makefile
TOP_DIR = ../..
DEPLOY_RUNTIME ?= /kb/runtime
TARGET ?= /kb/deployment

CLIENT_TESTS = $(wildcard t/client-tests/*.t)
SCRIPTS_TESTS = $(wildcard t/script-tests/*.t)
SERVER_TESTS = $(wildcard t/server-tests/*.t)

#for the reboot_service script, we need to get a path to dev_container/modules/"module_name".  We can do this simply
#by getting the absolute path to this makefile.  Note that very old versions of make might not support this line.
ROOT_DEV_MODULE_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))

# including the common makefile gives us a handle to the service directory.  This is
# where we will (for now) dump the service log files
include $(TOP_DIR)/tools/Makefile.common
$(SERVICE_DIR) ?= /kb/deployment/services/$(SERVICE)
PID_FILE = $(SERVICE_DIR)/service.pid
ACCESS_LOG_FILE = $(SERVICE_DIR)/log/access.log
ERR_LOG_FILE = $(SERVICE_DIR)/log/error.log

# make sure our make test works
.PHONY : test

# default target is all, which compiles the typespec and builds documentation
default: all

all: compile-typespec build-docs

compile-typespec:
	mkdir -p lib/biokbase/$(SERVICE_NAME)
	mkdir -p lib/javascript/$(SERVICE_NAME)
	mkdir -p scripts
	compile_typespec \
		--psgi $(SERVICE_PSGI_FILE) \
		--impl Bio::KBase::$(SERVICE_NAME)::Impl \
		--service Bio::KBase::$(SERVICE_NAME)::Service \
		--client Bio::KBase::$(SERVICE_NAME)::Client \
		--py biokbase/$(SERVICE_NAME)/Client \
		--js javascript/$(SERVICE_NAME)/Client \
		--scripts scripts \
		$(SERVICE_NAME).spec lib
#	rm -r Bio # For some strange reason, compile_typespec always creates this directory in the root dir!

build-docs: compile-typespec
	mkdir -p docs
	pod2html --infile=lib/Bio/KBase/$(SERVICE_NAME)/Client.pm --outfile=docs/$(SERVICE_NAME).html
	rm -f pod2htmd.tmp

# here are the standard KBase test targets (test, test-all, deploy-client, deploy-scripts, & deploy-service)
test: test-client test-scripts

test-all: test-service test-client test-scripts

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
	@echo "scripts are not yet ready to be tested."

test-service:
	$(DEPLOY_RUNTIME)/bin/perl -Ilib -It $(TOP_DIR)/modules/$(SERVICE)/t/client-tests/testProteinInfoService.t --serviceName $(SERVICE_NAME) --localServer


# here are the standard KBase deployment targets (deploy, deploy-all, deploy-client, deploy-scripts, & deploy-service)
# deploy-all is deprecated, deploy takes its place
#deploy: deploy-client
#	@echo "OK... Done deploying $(SERVICE)."

deploy: deploy-client deploy-service
	@echo "OK... Done deploying ALL artifacts (includes clients, scripts and server) of $(SERVICE)."

deploy-client: compile-typespec deploy-libs deploy-scripts build-docs deploy-docs

deploy-libs:
	mkdir -p $(TARGET)/lib/Bio/KBase/$(SERVICE_NAME)
	mkdir -p $(TARGET)/lib/biokbase/$(SERVICE_NAME)
	mkdir -p $(TARGET)/lib/javascript/$(SERVICE_NAME)
	cp lib/Bio/KBase/$(SERVICE_NAME)/Client.pm $(TARGET)/lib/Bio/KBase/$(SERVICE_NAME)/.
	cp lib/biokbase/$(SERVICE_NAME)/* $(TARGET)/lib/biokbase/$(SERVICE_NAME)/.
	cp lib/javascript/$(SERVICE_NAME)/* $(TARGET)/lib/javascript/$(SERVICE_NAME)/.
	@echo "deployed clients of $(SERVICE)."

deploy-scripts:
	@echo "scripts are not yet ready to be deployed."

deploy-docs: build-docs
	mkdir -p $(SERVICE_DIR)/webroot
	cp docs/*.html $(SERVICE_DIR)/webroot/.


# deploys all libraries and scripts needed to start the server
deploy-service: compile-typespec deploy-server-libs deploy-server-scripts

deploy-server-libs:
	mkdir -p $(TARGET)/lib/Bio/KBase/$(SERVICE_NAME)
	mkdir -p $(TARGET)/lib/Bio/KBase/$(SERVICE_NAME)/Browser
	cp lib/Bio/KBase/$(SERVICE_NAME)/Service.pm $(TARGET)/lib/Bio/KBase/$(SERVICE_NAME)/.
	cp lib/Bio/KBase/$(SERVICE_NAME)/ACL.pm $(TARGET)/lib/Bio/KBase/$(SERVICE_NAME)/.
	cp lib/Bio/KBase/$(SERVICE_NAME)/Description.pm $(TARGET)/lib/Bio/KBase/$(SERVICE_NAME)/.
	cp lib/Bio/KBase/$(SERVICE_NAME)/Gene.pm $(TARGET)/lib/Bio/KBase/$(SERVICE_NAME)/.
	cp lib/Bio/KBase/$(SERVICE_NAME)/Genome.pm $(TARGET)/lib/Bio/KBase/$(SERVICE_NAME)/.
	cp lib/Bio/KBase/$(SERVICE_NAME)/GenomicsUtils.pm $(TARGET)/lib/Bio/KBase/$(SERVICE_NAME)/.
	cp lib/Bio/KBase/$(SERVICE_NAME)/Regulon.pm $(TARGET)/lib/Bio/KBase/$(SERVICE_NAME)/.
	cp lib/Bio/KBase/$(SERVICE_NAME)/Scaffold.pm $(TARGET)/lib/Bio/KBase/$(SERVICE_NAME)/.
	cp lib/Bio/KBase/$(SERVICE_NAME)/Vector.pm $(TARGET)/lib/Bio/KBase/$(SERVICE_NAME)/.
	cp lib/Bio/KBase/$(SERVICE_NAME)/Browser/*.pm $(TARGET)/lib/Bio/KBase/$(SERVICE_NAME)/Browser/.
	cp $(TOP_DIR)/modules/$(SERVICE)/lib/Bio/KBase/$(SERVICE_NAME)/Impl.pm $(TARGET)/lib/Bio/KBase/$(SERVICE_NAME)/.
	cat deploy.cfg >> $(TARGET)/deployment.cfg
# no Util.pm file
#	cp $(TOP_DIR)/modules/$(SERVICE)/lib/Bio/KBase/$(SERVICE_NAME)/Util.pm $(TARGET)/lib/Bio/KBase/$(SERVICE_NAME)/.
	cp $(TOP_DIR)/modules/$(SERVICE)/lib/$(SERVICE_PSGI_FILE) $(TARGET)/lib/.
	mkdir -p $(SERVICE_DIR)
	@echo "deployed server for $(SERVICE)."

# deploys scripts to target (usually set to /kb/deployment)
deploy-script-wrappers:
	$(TOOLS_DIR)/deploy-wrappers \
                --jsonCommandsFile COMMANDS.json \
                --irisCommandsFile COMMANDS \
                --target $(TARGET) \
                --devContainerToolsDir $(TOOLS_DIR)

undeploy-script-wrappers:
	$(TOOLS_DIR)/deploy-wrappers \
                --jsonCommandsFile COMMANDS.json \
                --irisCommandsFile COMMANDS \
                --target $(TARGET) \
                --devContainerToolsDir $(TOOLS_DIR) \
                --undeploy

# creates script wrappers in dev_container/bin without copying scripts (this is
# how compile_typespec and kb_seed scripts are put on the path after ‘make’
build-dev-container-script-wrappers:
	$(TOOLS_DIR)/deploy-wrappers \
                --jsonCommandsFile COMMANDS.json \
                --irisCommandsFile COMMANDS \
                --target $(TOP_DIR) \
                --no-copyScripts \
                --devContainerToolsDir $(TOOLS_DIR)

clean-dev-container-script-wrappers:
	$(TOOLS_DIR)/deploy-wrappers \
                --jsonCommandsFile COMMANDS.json \
                --irisCommandsFile COMMANDS \
                --target $(TOP_DIR) \
                --no-copyScripts \
                --devContainerToolsDir $(TOOLS_DIR) \
                --undeploy


# creates start/stop/reboot scripts and copies them to the deployment target
deploy-server-scripts:
	# First create the start script (should be a better way to do this...)
	@echo '#!/bin/sh' > ./start_service
	@echo "echo starting $(SERVICE) server." >> ./start_service
	@echo 'export PERL5LIB=$$PERL5LIB:$(TARGET)/lib' >> ./start_service
	@echo 'export KB_DEPLOYMENT_CONFIG=$(TARGET)/deployment.cfg' >> ./start_service
	@echo 'export SERVICE=$(SERVICE)' >> ./start_service
	@echo '#uncomment to debug: export STARMAN_DEBUG=1' >> ./start_service
	@echo "$(DEPLOY_RUNTIME)/bin/starman --listen :$(SERVICE_PORT) --pid $(PID_FILE) --daemonize \\" >> ./start_service
	@echo "  --access-log $(ACCESS_LOG_FILE) \\" >>./start_service
	@echo "  --error-log $(ERR_LOG_FILE) \\" >> ./start_service
	@echo "  $(TARGET)/lib/$(SERVICE_PSGI_FILE)" >> ./start_service
	@echo "echo $(SERVICE) server is listening on port $(SERVICE_PORT).\n" >> ./start_service
	# Second, create a debug start script that is not daemonized
	@echo '#!/bin/sh' > ./debug_start_service
	@echo 'export PERL5LIB=$$PERL5LIB:$(TARGET)/lib' >> ./debug_start_service
	@echo 'export KB_DEPLOYMENT_CONFIG=$(TARGET)/deployment.cfg' >> ./debug_start_service
	@echo 'export SERVICE=$(SERVICE)' >> ./debug_start_service
	@echo 'export STARMAN_DEBUG=1' >> ./debug_start_service
	@echo "$(DEPLOY_RUNTIME)/bin/starman --listen :$(SERVICE_PORT) --workers 1 \\" >> ./debug_start_service
	@echo "    $(TARGET)/lib/$(SERVICE_PSGI_FILE)" >> ./debug_start_service
	# Second create the stop script (should be a better way to do this...)
	@echo '#!/bin/sh' > ./stop_service
	@echo "echo trying to stop $(SERVICE) server." >> ./stop_service
	@echo "pid_file=$(PID_FILE)" >> ./stop_service
	@echo "if [ ! -f \$$pid_file ] ; then " >> ./stop_service
	@echo "\techo \"No pid file: \$$pid_file found for server $(SERVICE).\"\n\texit 1\nfi" >> ./stop_service
	@echo "pid=\$$(cat \$$pid_file)\nkill \$$pid\n" >> ./stop_service
	# Finally create a script to reboot the service by stopping, redeploying the service, and starting again
	@echo '#!/bin/sh' > ./reboot_service
	@echo '# auto-generated script to stop the service, redeploy server implementation, and start the servce' >> ./reboot_service
	@echo "./stop_service\ncd $(ROOT_DEV_MODULE_DIR)\nmake deploy-server-libs\ncd -\n./start_service" >> ./reboot_service
	# Actually run the deployment of these scripts
	chmod +x start_service stop_service reboot_service debug_start_service
	mkdir -p $(SERVICE_DIR)
	mkdir -p $(SERVICE_DIR)/log
	cp start_service $(SERVICE_DIR)/
	cp debug_start_service $(SERVICE_DIR)/
	cp stop_service $(SERVICE_DIR)/
	cp reboot_service $(SERVICE_DIR)/

undeploy:
	rm -rfv $(SERVICE_DIR)
	rm -rfv $(TARGET)/lib/Bio/KBase/$(SERVICE_NAME)
	rm -rfv $(TARGET)/lib/$(SERVICE_PSGI_FILE)
	rm -rfv $(TARGET)/lib/biokbase/$(SERVICE_NAME)
	rm -rfv $(TARGET)/lib/javascript/$(SERVICE_NAME)
	rm -rfv $(TARGET)/docs/$(SERVICE_NAME)
	@echo "OK ... Removed all deployed files."

# remove files generated by building the server
clean:
	rm -f lib/Bio/KBase/$(SERVICE_NAME)/Client.pm
	rm -f lib/Bio/KBase/$(SERVICE_NAME)/Service.pm
	rm -f lib/$(SERVICE_PSGI_FILE)
	rm -rf lib/biokbase
	rm -rf lib/javascript
	rm -rf docs
	rm -rf scripts
	rm -f start_service stop_service reboot_service debug_start_service

