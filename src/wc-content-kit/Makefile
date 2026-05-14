# wc-content-kit — build orchestration
#
# Builds three Vue/web-component bundles (mermaid, markdown, chartjs) and
# stages their dist output under public/wc/{name}/ so the http.static entry
# (declared in _index.yaml) can serve them.
#
# Usage:
#   make build         build all three components
#   make clean         remove node_modules and built bundles
#   make clean-build   clean + build
#
# Per-component shortcuts:
#   make build-mermaid
#   make build-markdown
#   make build-chartjs

PUBLIC_DIR = public

.PHONY: help build clean clean-build \
        build-mermaid build-markdown build-chartjs \
        install install-mermaid install-markdown install-chartjs

help:
	@echo "wc-content-kit Makefile"
	@echo ""
	@echo "  make build         Build all components (mermaid, markdown, chartjs)"
	@echo "  make clean         Remove node_modules and built bundles"
	@echo "  make clean-build   Clean and rebuild from scratch"
	@echo ""
	@echo "  make build-mermaid    Build mermaid only"
	@echo "  make build-markdown   Build markdown only"
	@echo "  make build-chartjs    Build chartjs only"

# ── Install dependencies ──

install: install-mermaid install-markdown install-chartjs

install-mermaid:
	cd frontend/mermaid && npm install

install-markdown:
	cd frontend/markdown && npm install

install-chartjs:
	cd frontend/chartjs && npm install

# ── Build ──

build: build-mermaid build-markdown build-chartjs

build-mermaid: install-mermaid
	@rm -rf $(PUBLIC_DIR)/mermaid
	cd frontend/mermaid && npm run build
	@cp -r frontend/mermaid/dist $(PUBLIC_DIR)/mermaid

build-markdown: install-markdown
	@rm -rf $(PUBLIC_DIR)/markdown
	cd frontend/markdown && npm run build
	@cp -r frontend/markdown/dist $(PUBLIC_DIR)/markdown

build-chartjs: install-chartjs
	@rm -rf $(PUBLIC_DIR)/chartjs
	cd frontend/chartjs && npm run build
	@cp -r frontend/chartjs/dist $(PUBLIC_DIR)/chartjs

# ── Clean ──

clean:
	rm -rf frontend/mermaid/node_modules frontend/mermaid/dist
	rm -rf frontend/markdown/node_modules frontend/markdown/dist
	rm -rf frontend/chartjs/node_modules frontend/chartjs/dist
	rm -rf $(PUBLIC_DIR)

clean-build: clean build
