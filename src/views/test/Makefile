# PUBLIC_API_URL points at the test gateway (app:gateway), so the
# wippy-meta.json tests can fetch fixtures over HTTP.
test:
	PUBLIC_API_URL=http://localhost:19086 wippy test \
		-o wippy.views:api_router:default=app:api.public \
		-o wippy.views:env_storage:default=app:envs

lint:
	wippy lint --level error
