TEST_CONFIG ?=
TEST_CONFIG_ARG := $(if $(strip $(TEST_CONFIG)),--config "$(TEST_CONFIG)")

test:
	wippy test $(TEST_CONFIG_ARG) \
		-o wippy.session_util:api_router:default=app:api \
		-o wippy.llm:process_host:default=wippy.terminal:host \
		-o wippy.llm:env_storage:default=app:env_storage

lint:
	wippy lint $(TEST_CONFIG_ARG) --level error
