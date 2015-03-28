GO=gom
GOFLAGS=-race
SOURCES=*.go
EXECUTABLE=cacher_go

# If the first argument is "run"...
ifeq (run,$(firstword $(MAKECMDGOALS)))
# use the rest as arguments for "run"
RUN_ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
# ...and turn them into do-nothing targets
$(eval $(RUN_ARGS):;@:)
endif

all: bundle $(EXECUTABLE)

bundle:
	gom install

$(EXECUTABLE): $(SOURCES)
	$(GO) build $(GOFLAGS)

clean: $(EXECUTABLE)
	rm -f $(EXECUTABLE)

clean_bundle:
	rm -rf _vendor

run: $(EXECUTABLE)
	./$(EXECUTABLE) $(RUN_ARGS)
