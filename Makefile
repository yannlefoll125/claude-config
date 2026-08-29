BINDIR ?= $(HOME)/.local/bin

.PHONY: install uninstall

install:
	mkdir -p $(BINDIR)
	ln -sf $(CURDIR)/claude-config-install $(BINDIR)/claude-config-install
	@echo "Linked $(BINDIR)/claude-config-install -> $(CURDIR)/claude-config-install"

uninstall:
	rm -f $(BINDIR)/claude-config-install
