TEST_CONFIG ?=
TEST_CONFIG_ARG := --config .wippy.yaml $(if $(strip $(TEST_CONFIG)),--config "$(TEST_CONFIG)")

test:
	wippy test $(TEST_CONFIG_ARG) \
		-o wippy.llm:process_host:default=wippy.terminal:host \
		-o wippy.llm:env_storage:default=app:env_storage

lint:
	wippy lint $(TEST_CONFIG_ARG) --level error

lockrefresh:
	wippy update $(TEST_CONFIG_ARG)
