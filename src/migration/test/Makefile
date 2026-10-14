test:
	wippy test \
		-o wippy.migration:app_db:default=app:db \
		-o wippy.bootloader:application_host:default=app:processes \
		-o wippy.bootloader:env_storage:default=app:env_storage

lint:
	wippy lint --level error

# Requires the disposable PostgreSQL database configured in _index.yaml.
test-postgres:
	MIGRATION_TEST_POSTGRES=true $(MAKE) test
