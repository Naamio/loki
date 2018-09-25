PRODUCT_NAME = loki
CONTAINER_URL = naamio/${PRODUCT_NAME}:0.0

clean:
	if	[ -d ".build" ]; then \
		rm -rf .build ; \
	fi

build: clean
	@echo --- Building
	swift build

test:
	swift test

test-linux:
	docker run -v $$(pwd):/tmp/${PRODUCT_NAME} -w /tmp/${PRODUCT_NAME} -it ibmcom/swift-ubuntu:4.2 swift test

run: build
	@echo --- Invoking executable
	./.build/debug/${PRODUCT_NAME}

build-release: clean
	docker run -v $$(pwd):/tmp/${PRODUCT_NAME} -w /tmp/${PRODUCT_NAME} -it ibmcom/swift-ubuntu:4.2 swift build -c release -Xcc -fblocks -Xlinker -L/usr/local/lib

clean-container:

	-docker stop $(CONTAINER_NAME)
	-docker rm $(CONTAINER_NAME)
	-docker rmi $(CONTAINER_URL)

build-container: clean-container build-release

	docker build -t $(CONTAINER_URL) .

.PHONY: clean build test run
