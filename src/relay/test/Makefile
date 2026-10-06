TEST_CONFIG ?=
TEST_CONFIG_ARG := $(if $(strip $(TEST_CONFIG)),--config "$(TEST_CONFIG)")

test:
	wippy test $(TEST_CONFIG_ARG) \
		-o wippy.relay:application_host:default=wippy.terminal:host \
		-o wippy.relay:user_security_scope:default=app:user

lint:
	wippy lint $(TEST_CONFIG_ARG) --level error
