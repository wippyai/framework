test:
	wippy test \
		-o wippy.usage:target_db:default=app:db \
		-o wippy.migration:app_db:default=app:db \
		-o wippy.bootloader:application_host:default=app:processes \
		-o wippy.bootloader:env_storage:default=app:env_storage

lint:
	wippy lint --level error

# Uses the disposable PostgreSQL database shared with the migration test setup.
test-postgres:
	wippy test \
		-o wippy.usage:target_db:default=app:postgres_db \
		-o wippy.migration:app_db:default=app:postgres_db \
		-o wippy.bootloader:application_host:default=app:processes \
		-o wippy.bootloader:env_storage:default=app:env_storage
