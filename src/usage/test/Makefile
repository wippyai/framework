test:
	wippy run test \
		-o wippy.usage:target_db:default=app:db \
		-o wippy.migration:app_db:default=app:db \
		-o wippy.bootloader:application_host:default=app:processes \
		-o wippy.bootloader:env_storage:default=app:env_storage

lint:
	wippy lint --level error
