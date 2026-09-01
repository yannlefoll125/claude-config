BINDIR ?= $(HOME)/.local/bin

.PHONY: install uninstall

install:
	mkdir -p $(BINDIR)
	ln -sf $(CURDIR)/claude-config-install $(BINDIR)/claude-config-install
	ln -sf $(CURDIR)/claude-config-push $(BINDIR)/claude-config-push
	@echo "Linked $(BINDIR)/claude-config-install -> $(CURDIR)/claude-config-install"
	@echo "Linked $(BINDIR)/claude-config-push -> $(CURDIR)/claude-config-push"

uninstall:
	rm -f $(BINDIR)/claude-config-install $(BINDIR)/claude-config-push
