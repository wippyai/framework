# Framework Module Publishing
# Hub rejects duplicate content, so unchanged packages are skipped automatically

PACKAGES_FLAT = migration embeddings views security docs terminal test
PACKAGES_SRC = actor agent bootloader llm relay usage

.PHONY: all publish-all $(PACKAGES_FLAT) $(PACKAGES_SRC) help

help:
	@echo "Wippy Framework Module Publishing"
	@echo ""
	@echo "Usage:"
	@echo "  make publish-all    Publish all packages (skips unchanged)"
	@echo "  make <package>      Publish specific package"
	@echo ""
	@echo "Flat packages:   $(PACKAGES_FLAT)"
	@echo "Src packages:    $(PACKAGES_SRC)"

publish-all: $(PACKAGES_FLAT) $(PACKAGES_SRC)
	@echo "All packages processed"

# Flat structure packages (wippy.yaml at package root)
$(PACKAGES_FLAT):
	@echo "Publishing $@..."
	@cd src/$@ && wippy publish || echo "$@ unchanged or failed"

# Src subfolder structure packages (wippy.yaml inside src/)
$(PACKAGES_SRC):
	@echo "Publishing $@..."
	@cd src/$@/src && wippy publish || echo "$@ unchanged or failed"
