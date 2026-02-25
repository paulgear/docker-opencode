REGISTRY=
LOGIN=paulgear
REPO=opencode
FLAGS_BUILD=
FLAGS_PUSH=
FLAGS_RUN=

.PHONY: build push run

default: build

build:
	docker build -t $(REGISTRY)$(LOGIN)/$(REPO) --build-arg https_proxy=${https_proxy} $(FLAGS_BUILD) .

push:	build
	docker push $(FLAGS_PUSH) $(REGISTRY)$(LOGIN)/$(REPO)

run:	build
	docker run --rm -ti $(FLAGS_RUN) $(REGISTRY)$(LOGIN)/$(REPO)
