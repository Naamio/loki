CONTAINER_URL = naamio/loki:0.0
CONTAINER_NAME = loki

clean:
	if	[ -d ".build" ]; then \
		rm -rf .build ; \
	fi

build: clean
	@echo --- Building
	swift build

test: build
	swift test

run: build
	@echo --- Invoking executable
	./.build/debug/Loki

build-release: clean
	docker run -v $$(pwd):/tmp/loki -w /tmp/loki -it ibmcom/swift-ubuntu:4.0 swift build -c release -Xcc -fblocks -Xlinker -L/usr/local/lib

clean-container:

	-docker stop $(CONTAINER_NAME)
	-docker rm $(CONTAINER_NAME)
	-docker rmi $(CONTAINER_URL)

build-container: clean-container build-release

	docker build -t $(CONTAINER_URL) .

.PHONY: clean build test run
