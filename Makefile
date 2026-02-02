REGISTRY=
LOGIN=paulgear
REPO=opencode

.PHONY: build push run

default: build

build:
	docker build -t $(REGISTRY)$(LOGIN)/$(REPO) --build-arg https_proxy=${https_proxy} .

push:	build
	docker push $(REGISTRY)$(LOGIN)/$(REPO)

run:	build
	docker run --rm -ti $(REGISTRY)$(LOGIN)/$(REPO)
