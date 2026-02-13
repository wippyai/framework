.PHONY: test test-integration test-e2e

test:
	wippy run test

test-integration:
	ENABLE_INTEGRATION_TESTS=true wippy run test

test-e2e:
	ENABLE_INTEGRATION_TESTS=true wippy run wippy.llm.e2e:integration_test
