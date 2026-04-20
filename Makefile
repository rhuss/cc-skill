.PHONY: validate install uninstall reinstall help

MARKETPLACE := skill-plugin-development
PLUGIN := skill@$(MARKETPLACE)

validate:
	claude plugin validate ./skill/

install:
	@# Remove existing plugin if installed
	@claude plugin rm $(PLUGIN) 2>/dev/null || true
	@# Remove existing marketplace if installed
	@claude plugin marketplace rm $(MARKETPLACE) 2>/dev/null || true
	@# Add marketplace
	@claude plugin marketplace add ./ && echo "Marketplace added."
	@# Install plugin
	claude plugin install $(PLUGIN)

uninstall:
	@echo "Removing plugin..."
	@claude plugin rm $(PLUGIN) 2>/dev/null || echo "Plugin not installed"
	@echo "Removing marketplace..."
	@claude plugin marketplace rm $(MARKETPLACE) 2>/dev/null || echo "Marketplace not installed"

reinstall: uninstall install

help:
	@echo "Available targets:"
	@echo "  validate    - Validate plugin manifest"
	@echo "  install     - Install or update plugin (idempotent)"
	@echo "  uninstall   - Remove plugin and marketplace"
	@echo "  reinstall   - Full uninstall and reinstall"
