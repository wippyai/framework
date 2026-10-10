TEST_CONFIG ?=
TEST_CONFIG_ARG := $(if $(strip $(TEST_CONFIG)),--config "$(TEST_CONFIG)")

lockrefresh:
	wippy update $(TEST_CONFIG_ARG) --src-dir ..
	wippy install $(TEST_CONFIG_ARG)

test:
	wippy test $(TEST_CONFIG_ARG) \
		-o wippy.relay:application_host:default=app:processes \
		-o wippy.relay:user_security_scope:default=app:user

lint:
	wippy lint $(TEST_CONFIG_ARG) --level error
