test:
	wippy test \
		-o wippy.views:api_router:default=app:api.public \
		-o wippy.views:env_storage:default=app:envs

lint:
	wippy lint --level error

# Metadata HTTP fixtures run on app:gateway in this test workspace.
export PUBLIC_API_URL := http://localhost:19086
