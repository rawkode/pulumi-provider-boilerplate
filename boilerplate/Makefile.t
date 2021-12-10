PROJECT_NAME := Pulumi [[ provider_name ]] Resource Provider

PACK             := [[ provider_name ]]
PROJECT          := github.com/[[ git_username ]]/pulumi-[[ provider_name]]

PROVIDER_DIR   := provider
SDK_DIR        := sdk

PROVIDER        := pulumi-resource-${PACK}
CODEGEN         := pulumi-gen-${PACK}
VERSION         ?= $(shell pulumictl get version)

VERSION_PATH    := ${PROVIDER_DIR}/pkg/version.Version

SCHEMA_FILE     := provider/cmd/pulumi-resource-[[ provider_name ]]/schema.yaml
GOPATH			:= $(shell go env GOPATH)

NODE_MODULE_NAME := [[ npm_username ]]/[[ provider_name ]]
NUGET_PKG_NAME   := [[ nuget_username ]].[[ provider_name ]]

WORKING_DIR     := $(shell pwd)
TESTPARALLELISM := 4

default:: gen provider ensure

ensure::
	cd provider && go mod tidy
	cd sdk && go mod tidy
	cd tests && go mod tidy

gen::
	(cd provider && go build -a -o $(WORKING_DIR)/bin/${CODEGEN} -ldflags "-X ${PROJECT}/${VERSION_PATH}=${VERSION}" ${PROJECT}/${PROVIDER_DIR}/cmd/$(CODEGEN))

provider::
	(cd provider && VERSION=${VERSION} go generate cmd/${PROVIDER}/main.go)
	(cd provider && go build -a -o $(WORKING_DIR)/bin/${PROVIDER} -ldflags "-X ${PROJECT}/${VERSION_PATH}=${VERSION}" $(PROJECT)/${PROVIDER_DIR}/cmd/$(PROVIDER))

provider_debug::
	(cd provider && go build -a -o $(WORKING_DIR)/bin/${PROVIDER} -gcflags="all=-N -l" -ldflags "-X ${PROJECT}/${VERSION_PATH}=${VERSION}" $(PROJECT)/${PROVIDER_DIR}/cmd/$(PROVIDER))

test_provider::
	cd provider/pkg && go test -short -v -count=1 -cover -timeout 2h -parallel ${TESTPARALLELISM} ./...

dotnet_sdk:: DOTNET_VERSION := $(shell pulumictl get version --language dotnet)
dotnet_sdk::
	rm -rf sdk/dotnet
	$(WORKING_DIR)/bin/$(CODEGEN) -version=${DOTNET_VERSION} dotnet $(SCHEMA_FILE) $(CURDIR)/$(SDK_PATH)/dotnet
	cd ${SDK_DIR}/dotnet/&& \
		echo "${DOTNET_VERSION}" >version.txt && \
		dotnet build /p:Version=${DOTNET_VERSION}

go_sdk::
	rm -rf sdk/go
	$(WORKING_DIR)/bin/$(CODEGEN) -version=${VERSION} go $(SCHEMA_FILE) $(CURDIR)/$(SDK_PATH)/go

nodejs_sdk:: VERSION := $(shell pulumictl get version --language javascript)
nodejs_sdk::
	rm -rf sdk/nodejs
	$(WORKING_DIR)/bin/$(CODEGEN) -version=${VERSION} nodejs $(SCHEMA_FILE) $(CURDIR)/$(SDK_PATH)/nodejs
	cd ${SDK_DIR}/nodejs/ && \
		yarn install && \
		yarn run tsc
	cp README.md LICENSE ${SDK_DIR}/nodejs/package.json ${SDK_DIR}/nodejs/yarn.lock ${SDK_DIR}/nodejs/bin/
	sed -i.bak 's/$${VERSION}/$(VERSION)/g' ${SDK_DIR}/nodejs/bin/package.json

python_sdk:: PYPI_VERSION := $(shell pulumictl get version --language python)
python_sdk::
	rm -rf sdk/python
	$(WORKING_DIR)/bin/$(CODEGEN) -version=${VERSION} python $(SCHEMA_FILE) $(CURDIR)/$(SDK_PATH)/python
	cp README.md ${SDK_DIR}/python/
	cd ${SDK_DIR}/python/ && \
		python3 setup.py clean --all 2>/dev/null && \
		rm -rf ./bin/ ../python.bin/ && cp -R . ../python.bin && mv ../python.bin ./bin && \
		sed -i.bak -e 's/^VERSION = .*/VERSION = "$(PYPI_VERSION)"/g' -e 's/^PLUGIN_VERSION = .*/PLUGIN_VERSION = "$(VERSION)"/g' ./bin/setup.py && \
		rm ./bin/setup.py.bak && \
		cd ./bin && python3 setup.py build sdist

.PHONY: build
build:: gen provider dotnet_sdk go_sdk nodejs_sdk python_sdk

# Required for the codegen action that runs in pulumi/pulumi
only_build:: build

lint::
	for DIR in "provider" "sdk" "tests" ; do \
		pushd $$DIR && golangci-lint run -c ../.golangci.yml --timeout 10m && popd ; \
	done


install:: install_nodejs_sdk install_dotnet_sdk
	cp $(WORKING_DIR)/bin/${PROVIDER} ${GOPATH}/bin


GO_TEST 	 := go test -v -count=1 -cover -timeout 2h -parallel ${TESTPARALLELISM}

test_all::
	cd provider/pkg && $(GO_TEST) ./...
	cd tests/sdk/nodejs && $(GO_TEST) ./...
	cd tests/sdk/python && $(GO_TEST) ./...
	cd tests/sdk/dotnet && $(GO_TEST) ./...
	cd tests/sdk/go && $(GO_TEST) ./...

install_dotnet_sdk::
	rm -rf $(WORKING_DIR)/nuget/$(NUGET_PKG_NAME).*.nupkg
	mkdir -p $(WORKING_DIR)/nuget
	find . -name '*.nupkg' -print -exec cp -p {} ${WORKING_DIR}/nuget \;

install_python_sdk::
	#target intentionally blank

install_go_sdk::
	#target intentionally blank

install_nodejs_sdk::
	-yarn unlink --cwd $(WORKING_DIR)/sdk/nodejs/bin
	yarn link --cwd $(WORKING_DIR)/sdk/nodejs/bin
