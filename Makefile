# -----------------------------------------------------------------------------
# global

.DEFAULT_GOAL := test
comma := ,
empty :=
space := $(empty) $(empty)

# -----------------------------------------------------------------------------
# go

GO_PATH ?= $(shell go env GOPATH)

PKG := $(subst $(GO_PATH)/src/,,$(CURDIR))
CGO_ENABLED ?= 0
GO_BUILDTAGS=osusergo,netgo,static
GO_LDFLAGS=-s -w -linkmode internal "-extldflags=-static-pie -fno-PIC"
GO_FLAGS ?= -tags='$(subst $(space),$(comma),${GO_BUILDTAGS})' -ldflags='${GO_LDFLAGS}' -installsuffix=netgo
ifneq (${VERSION},)
	GO_LDFLAGS+=-X main.version=${VERSION}
endif

GOBIN := ${CURDIR}/bin
TOOLS_DIR := ${CURDIR}/tools
TOOLS_BIN := ${TOOLS_DIR}/bin
TOOLS := $(shell pushd ${TOOLS_DIR} > /dev/null 2>&1 && go list -v -f='{{ join .Imports " " }}' -tags=tools)

GO_PKGS := ./...

GO_TEST ?= ${TOOLS_BIN}/gotestsum --
GO_TEST_PKGS ?= $(shell go list -f='{{ if (or .TestGoFiles .XTestGoFiles .TestEmbedFiles .XTestEmbedFiles) }}{{ .ImportPath }}{{ end }}' ./...)
GO_TEST_FLAGS ?= -race -count=1
GO_TEST_FUNC ?= .
GO_BENCH_FLAGS ?= -benchmem
GO_BENCH_FUNC ?= .
GO_LINT_FLAGS ?=

# Set build environment
JOBS := $(shell getconf _NPROCESSORS_CONF)
# If $CIRCLECI is true, assume linux environment, parse actual share CPU count.
# $CIRCLECI env is automatically set by CircleCI. See also https://circleci.com/docs/2.0/env-vars/#built-in-environment-variables
ifeq ($(CIRCLECI),true)
	# https://circleci.com/changelog#container-cgroup-limits-now-visible-inside-the-docker-executor
	JOBS := $(shell echo $$(($$(cat /sys/fs/cgroup/cpu/cpu.shares) / 1024)))
endif

# -----------------------------------------------------------------------------
# defines

define target
@printf "+ $(patsubst ,$@,$(1))\\n" >&2
endef

# -----------------------------------------------------------------------------
# target

##@ build

.PHONY: ${GOBIN}/$(notdir ${PKG})
${GOBIN}/$(notdir ${PKG}):
	$(call target,build)
	@mkdir -p ./bin
	CGO_ENABLED=0 go build -v ${GO_FLAGS} -o ./bin/$(notdir ${PKG}) ${PKG}

build: ${GOBIN}/$(notdir ${PKG})  ## Build binary.


##@ test, coverage

export GOTESTSUM_FORMAT=standard-verbose

.PHONY: test
test: CGO_ENABLED=1
test: testdata tools/bin/gotestsum  ## Runs package test including race condition.
	$(call target)
	@CGO_ENABLED=${CGO_ENABLED} ${GO_TEST} ${GO_TEST_FLAGS} -run=${GO_TEST_FUNC} $(strip ${GO_FLAGS}) ${GO_TEST_PKGS}
	@pushd testdata > /dev/null 2>&1; \
		CGO_ENABLED=${CGO_ENABLED} ${GO_TEST} ${GO_TEST_FLAGS} -run=${GO_TEST_FUNC} $(strip ${GO_FLAGS}) ${GO_TEST_PKGS}

.PHONY: coverage
coverage: CGO_ENABLED=1
coverage: testdata tools/bin/gotestsum  ## Takes packages test coverage.
	$(call target)
	CGO_ENABLED=${CGO_ENABLED} ${GO_TEST} ${GO_TEST_FLAGS} -covermode=atomic -coverpkg=./... -coverprofile=coverage.out $(strip ${GO_FLAGS}) ${GO_PKGS}
	@pushd testdata > /dev/null 2>&1; \
		CGO_ENABLED=${CGO_ENABLED} ${GO_TEST} ${GO_TEST_FLAGS} -covermode=atomic -coverpkg=./... -coverprofile=coverage.out $(strip ${GO_FLAGS}) ${GO_PKGS}

.PHONY: testdata
testdata: build tools/bin/protoc-gen-go
testdata: testdata/types testdata/k8s.io/apimachinery/pkg/apis/meta/v1

.PHONY: testdata/types
testdata/types:
	@PATH="${GOBIN}:${TOOLS_BIN}:${PATH}" protoc -I. -I${GO_PATH}/src --go_out=${GO_PATH}/src --deepcopy_out=${GO_PATH}/src ./testdata/types/types.proto

.PHONY: testdata/k8s.io/apimachinery/pkg/apis/meta/v1
testdata/k8s.io/apimachinery/pkg/apis/meta/v1:
	@PATH="${GOBIN}:${TOOLS_BIN}:${PATH}" protoc -I. -I${GO_PATH}/src --go_out=${GO_PATH}/src --deepcopy_out=${GO_PATH}/src ./testdata/k8s.io/apimachinery/pkg/apis/meta/v1/meta.proto


##@ fmt, lint

.PHONY: lint
lint: fmt lint/golangci-lint  ## Run all linters.

.PHONY: fmt
fmt: tools/goimports tools/gofumpt  ## Run goimports and gofumpt.
	$(call target)
	find . -type f -name '*.go' -and -not -name '*.pb.go' -and -not -iwholename '*vendor*' | xargs -P ${JOBS} ${TOOLS_BIN}/goimports -local=${PKG},$(subst /protocol,,$(PKG)) -w
	find . -type f -name '*.go' -and -not -name '*.pb.go' -and -not -iwholename '*vendor*' | xargs -P ${JOBS} ${TOOLS_BIN}/gofumpt -s -extra -w

.PHONY: lint/golangci-lint
lint/golangci-lint: tools/golangci-lint .golangci.yml  ## Run golangci-lint.
	$(call target)
	${TOOLS_BIN}/golangci-lint -j ${JOBS} run $(strip ${GO_LINT_FLAGS}) ./...


##@ tools

.PHONY: tools
tools: tools/bin/''  ## Install tools

tools/%:  ## install an individual dependent tool
	@${MAKE} tools/bin/$* 1>/dev/null

tools/bin/%: ${TOOLS_DIR}/go.mod ${TOOLS_DIR}/go.sum
	@pushd ${TOOLS_DIR} > /dev/null 2>&1; \
		for t in ${TOOLS}; do \
			if [ -z '$*' ] || [ $$(basename $$t) = '$*' ]; then \
				echo "Install $$t ..." >&2; \
				GOBIN=${TOOLS_BIN} CGO_ENABLED=0 go install -mod=readonly ${GO_FLAGS} "$${t}"; \
			fi \
		done


##@ clean

.PHONY: clean
clean:  ## Cleanups binaries and extra files in the package.
	$(call target)
	@rm -rf ${GOBIN} ${TOOLS_DIR}/bin *.out *.test *.prof coverage.*


##@ miscellaneous

.PHONY: todo
TODO:  ## Print the all of (TODO|BUG|XXX|FIXME|NOTE) in packages.
	@grep -E '(TODO|BUG|XXX|FIXME)(\(.+\):|:)' $(shell find . -type f -name '*.go' -and -not -iwholename '*vendor*') || true

.PHONY: nolint
nolint:  ## Print the all of //nolint:... pragma in packages.
	@grep -E -C 3 '//nolint.+' $(shell find . -type f -name '*.go' -and -not -iwholename '*vendor*' -and -not -iwholename '*internal*') || true

.PHONY: env/%
env/%: ## Print the value of MAKEFILE_VARIABLE. Use `make env/JOBS` or etc.
	@echo $($*)


##@ help

.PHONY: help
help: ## Show make target help.
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[33m<target>\033[0m\n"} /^[a-zA-Z_0-9\/%_-]+:.*?##/ { printf "  \033[32m%-20s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)
