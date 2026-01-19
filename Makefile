# ============================================================================
# Dotfiles Makefile - Linux Native
# Modern shell environment with automated dependency management
# ============================================================================

.PHONY: all install deps link config starship zoxide fzf eza bat clean uninstall help

# Colors for output
BLUE := \033[0;34m
GREEN := \033[0;32m
YELLOW := \033[1;33m
NC := \033[0m # No Color

# Directories
CONFIG_DIR := $(HOME)/.config
SHELL_CONFIG_DIR := $(CONFIG_DIR)/shell
LOCAL_BIN := $(HOME)/.local/bin
DOTFILES_DIR := $(CURDIR)/dotfiles

# Shell detection
SHELL_TYPE := $(shell basename $(SHELL))

# Default target
all: install

help:
	@echo "$(BLUE)Dotfiles Makefile - Available targets:$(NC)"
	@echo ""
	@echo "  $(GREEN)install$(NC)     - Full installation (deps + link + config)"
	@echo "  $(GREEN)deps$(NC)        - Install modern CLI tools"
	@echo "  $(GREEN)link$(NC)        - Create symbolic links"
	@echo "  $(GREEN)config$(NC)      - Configure shell initialization"
	@echo "  $(GREEN)clean$(NC)       - Remove symbolic links"
	@echo "  $(GREEN)uninstall$(NC)   - Full uninstall (clean + remove deps)"
	@echo "  $(GREEN)help$(NC)        - Show this help message"
	@echo ""
	@echo "$(BLUE)Individual tool installation:$(NC)"
	@echo "  starship, zoxide, fzf, eza, bat"

# ============================================================================
# Main Targets
# ============================================================================

install: deps link config
	@echo "$(GREEN)✓ Installation completed successfully!$(NC)"
	@echo "$(YELLOW)Please restart your shell or run:$(NC)"
	@echo "  source ~/.bashrc   (for Bash)"
	@echo "  source ~/.zshrc    (for Zsh)"

deps: starship zoxide fzf eza bat
	@echo "$(GREEN)✓ All dependencies installed$(NC)"

link:
	@echo "$(BLUE)Creating symbolic links...$(NC)"
	@mkdir -p $(SHELL_CONFIG_DIR)
	# Link shell modules
	@ln -sf $(DOTFILES_DIR)/shell/aliases.sh $(SHELL_CONFIG_DIR)/aliases.sh
	@ln -sf $(DOTFILES_DIR)/shell/functions.sh $(SHELL_CONFIG_DIR)/functions.sh
	@ln -sf $(DOTFILES_DIR)/shell/exports.sh $(SHELL_CONFIG_DIR)/exports.sh
	# Link entry point files
	@ln -sf $(DOTFILES_DIR)/bashrc $(HOME)/.bashrc
	@ln -sf $(DOTFILES_DIR)/zshrc $(HOME)/.zshrc
	@echo "$(GREEN)✓ Symbolic links created$(NC)"

config:
	@echo "$(BLUE)Configuring Starship prompt...$(NC)"
	@mkdir -p $(CONFIG_DIR)
	@ln -sf $(DOTFILES_DIR)/config/starship.toml $(CONFIG_DIR)/starship.toml
	@echo "$(GREEN)✓ Shell configuration completed$(NC)"
	@echo "$(YELLOW)Note: Entry point files (.bashrc/.zshrc) are now linked directly$(NC)"

clean:
	@echo "$(BLUE)Removing symbolic links...$(NC)"
	@rm -f $(SHELL_CONFIG_DIR)/aliases.sh
	@rm -f $(SHELL_CONFIG_DIR)/functions.sh
	@rm -f $(SHELL_CONFIG_DIR)/exports.sh
	@rm -f $(CONFIG_DIR)/starship.toml
	@rm -f $(HOME)/.bashrc
	@rm -f $(HOME)/.zshrc
	@echo "$(GREEN)✓ Symbolic links removed$(NC)"
	@echo "$(YELLOW)Warning: Your original .bashrc/.zshrc have been removed$(NC)"
	@echo "$(YELLOW)Backup them before running 'make clean' if needed$(NC)"

uninstall: clean
	@echo "$(YELLOW)To completely remove installed tools, run:$(NC)"
	@echo "  sudo apt remove starship zoxide fzf eza bat  # Debian/Ubuntu"
	@echo "  or manually remove binaries from $(LOCAL_BIN)"

# ============================================================================
# Tool Installation (Distribution-agnostic)
# ============================================================================

starship:
	@echo "$(BLUE)Installing Starship prompt...$(NC)"
	@if command -v starship >/dev/null 2>&1; then \
		echo "$(YELLOW)! Starship already installed$(NC)"; \
	elif command -v cargo >/dev/null 2>&1; then \
		cargo install starship --locked; \
	else \
		mkdir -p $(LOCAL_BIN); \
		curl -sS https://starship.rs/install.sh | sh -s -- --bin-dir $(LOCAL_BIN) -y; \
	fi
	@echo "$(GREEN)✓ Starship installed$(NC)"

zoxide:
	@echo "$(BLUE)Installing Zoxide...$(NC)"
	@if command -v zoxide >/dev/null 2>&1; then \
		echo "$(YELLOW)! Zoxide already installed$(NC)"; \
	elif command -v cargo >/dev/null 2>&1; then \
		cargo install zoxide --locked; \
	else \
		mkdir -p $(LOCAL_BIN); \
		curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash; \
	fi
	@echo "$(GREEN)✓ Zoxide installed$(NC)"

fzf:
	@echo "$(BLUE)Installing FZF...$(NC)"
	@if command -v fzf >/dev/null 2>&1; then \
		echo "$(YELLOW)! FZF already installed$(NC)"; \
	else \
		if [ -d $(HOME)/.fzf ]; then \
			cd $(HOME)/.fzf && git pull; \
		else \
			git clone --depth 1 https://github.com/junegunn/fzf.git $(HOME)/.fzf; \
		fi; \
		$(HOME)/.fzf/install --key-bindings --completion --no-update-rc; \
	fi
	@echo "$(GREEN)✓ FZF installed$(NC)"

eza:
	@echo "$(BLUE)Installing Eza (modern ls)...$(NC)"
	@if command -v eza >/dev/null 2>&1; then \
		echo "$(YELLOW)! Eza already installed$(NC)"; \
	elif command -v cargo >/dev/null 2>&1; then \
		cargo install eza; \
	else \
		mkdir -p $(LOCAL_BIN); \
		echo "$(YELLOW)! Installing eza from GitHub releases$(NC)"; \
		LATEST=$$(curl -s https://api.github.com/repos/eza-community/eza/releases/latest | grep "tag_name" | cut -d '"' -f 4); \
		curl -sL "https://github.com/eza-community/eza/releases/download/$${LATEST}/eza_x86_64-unknown-linux-gnu.tar.gz" | tar xz -C $(LOCAL_BIN); \
	fi
	@echo "$(GREEN)✓ Eza installed$(NC)"

bat:
	@echo "$(BLUE)Installing Bat (modern cat)...$(NC)"
	@if command -v bat >/dev/null 2>&1 || command -v batcat >/dev/null 2>&1; then \
		echo "$(YELLOW)! Bat already installed$(NC)"; \
	elif command -v cargo >/dev/null 2>&1; then \
		cargo install bat; \
	else \
		mkdir -p $(LOCAL_BIN); \
		echo "$(YELLOW)! Installing bat from GitHub releases$(NC)"; \
		LATEST=$$(curl -s https://api.github.com/repos/sharkdp/bat/releases/latest | grep "tag_name" | cut -d '"' -f 4); \
		curl -sL "https://github.com/sharkdp/bat/releases/download/$${LATEST}/bat-$${LATEST}-x86_64-unknown-linux-gnu.tar.gz" | tar xz -C /tmp; \
		mv /tmp/bat-$${LATEST}-x86_64-unknown-linux-gnu/bat $(LOCAL_BIN)/; \
		rm -rf /tmp/bat-$${LATEST}-x86_64-unknown-linux-gnu; \
	fi
	@if command -v batcat >/dev/null 2>&1 && ! command -v bat >/dev/null 2>&1; then \
		ln -sf $$(which batcat) $(LOCAL_BIN)/bat; \
	fi
	@echo "$(GREEN)✓ Bat installed$(NC)"

# ============================================================================
# Optional: Install additional modern tools
# ============================================================================

extra-tools:
	@echo "$(BLUE)Installing additional modern tools...$(NC)"
	@$(MAKE) -s install-fd
	@$(MAKE) -s install-ripgrep
	@$(MAKE) -s install-delta
	@echo "$(GREEN)✓ Extra tools installed$(NC)"

install-fd:
	@if command -v fd >/dev/null 2>&1 || command -v fdfind >/dev/null 2>&1; then \
		echo "$(YELLOW)! fd already installed$(NC)"; \
	elif command -v cargo >/dev/null 2>&1; then \
		cargo install fd-find; \
	else \
		echo "$(YELLOW)! Install fd via package manager: apt install fd-find$(NC)"; \
	fi

install-ripgrep:
	@if command -v rg >/dev/null 2>&1; then \
		echo "$(YELLOW)! ripgrep already installed$(NC)"; \
	elif command -v cargo >/dev/null 2>&1; then \
		cargo install ripgrep; \
	else \
		echo "$(YELLOW)! Install ripgrep via package manager: apt install ripgrep$(NC)"; \
	fi

install-delta:
	@if command -v delta >/dev/null 2>&1; then \
		echo "$(YELLOW)! delta already installed$(NC)"; \
	elif command -v cargo >/dev/null 2>&1; then \
		cargo install git-delta; \
	else \
		echo "$(YELLOW)! Install delta via package manager or cargo$(NC)"; \
	fi
