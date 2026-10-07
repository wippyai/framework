TEST_CONFIG ?= .wippy.yaml
FACADE_SOURCE := $(abspath ..)

test:
	wippy test --config "$(TEST_CONFIG)" \
		-o "app.facade_test:source:directory=$(FACADE_SOURCE)" \
		-o wippy.facade:server:default=app:gateway \
		-o wippy.facade:router:default=app:api.public \
		-o "wippy.facade:public_files:directory=$(FACADE_SOURCE)/public/"

lint:
	wippy lint --config "$(TEST_CONFIG)" --level error
