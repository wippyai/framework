test: test-lua test-js

test-lua:
	wippy test \
		-o wippy.views:api_router:default=app:api.public \
		-o wippy.views:env_storage:default=app:envs

# The fragment realm stub's inline JavaScript, run against a pinned copy of the
# Web Host's import-map bootstrap helper. Needs Node.js 18 or later.
test-js:
	node --test js/fragment_stub.test.mjs

lint:
	wippy lint --level error

# Metadata HTTP fixtures run on app:gateway in this test workspace.
export PUBLIC_API_URL := http://localhost:19086
