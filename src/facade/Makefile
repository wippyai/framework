# Facade — Wippy Web Host shell
#
# The facade vendors a few CDN files from Wippy Web Host (public/@wippy-fe/)
# so they're available before the CDN URL is known (pre-config-fetch).
#
# Run `make sync` after every Wippy Web Host version bump to pull fresh copies.

# Web Host CDN base — update version when Wippy Web Host releases
WEB_HOST_CDN = https://web-host.wippy.ai/webcomponents-1.0.42

# Files to sync from CDN into public/@wippy-fe/
CDN_FILES = loading.js

.PHONY: sync help

help:
	@echo "Facade Makefile"
	@echo ""
	@echo "  make sync   Download vendored CDN files from Web Host"
	@echo ""
	@echo "Run sync after every Wippy Web Host version bump."

sync:
	@mkdir -p public/@wippy-fe
	@for f in $(CDN_FILES); do \
		echo "Downloading $$f..."; \
		curl -fSL "$(WEB_HOST_CDN)/@wippy-fe/$$f" -o "public/@wippy-fe/$$f"; \
	done
	@echo "Synced $(CDN_FILES) from $(WEB_HOST_CDN)"
