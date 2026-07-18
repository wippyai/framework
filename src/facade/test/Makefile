test:
	wippy run test \
		-o wippy.facade:server:default=app:gateway \
		-o wippy.facade:router:default=app:api.public \
		-o wippy.facade:public_files:directory=../public/

lint:
	wippy lint --level error
