SHELL=/bin/bash
DIR=$(shell pwd)
JQ_LATEST=$(shell curl -s https://api.github.com/repos/stedolan/jq/releases/latest | jq -r '.assets | .[] | select(.name | contains("linux64")) | .browser_download_url')
YQ_LATEST=$(shell curl -s https://api.github.com/repos/mikefarah/yq/releases/latest | jq -r '.assets | .[] | select(.name | contains("linux_amd64")) | .browser_download_url' | head -1)
NVIM_LATEST=$(shell curl -s https://api.github.com/repos/neovim/neovim/releases/latest | jq -r '.assets | .[] | select(.name | contains("linux64.tar")) | .browser_download_url' | head -1)
NODEJS_LATEST_VERSION=$(shell curl -s https://api.github.com/repos/nodejs/node/releases/latest | jq -r .tag_name)
NODEJS_LATEST=https://nodejs.org/dist/${NODEJS_LATEST_VERSION}/node-${NODEJS_LATEST_VERSION}-linux-x64.tar.xz

check-env:
ifndef GITHUB_TOKEN
	$(error GITHUB_TOKEN is undefined | Get it from https://github.com/settings/tokens)
endif

go-version:
ifndef GO_VERSION
	$(error GO_VERSION is undefined | Example: 1.8.0)
endif

GO_LATEST_VERSION=$(shell curl -sL https://golang.org/dl/ | grep -Eo 'go[0-9]{1,2}.[0-9]{1,2}.[0-9]{1,2}.linux-amd64.tar.gz' | grep ${GO_VERSION} | head -n 1)
GO_LATEST=https://go.dev/dl/${GO_LATEST_VERSION}

.PHONY: nvim

nvim: nvim-dir nvim-dependency nvim-download nvim-plugins

nvim-dir:
	@echo "Creating directories for nvim ..."
	mkdir -p ${HOME}/.local/bin ${HOME}/.local/nvim ${HOME}/.local/nodejs ${HOME}/.local/share/nvim/site/pack/coc/start ${HOME}/.zsh_history ${HOME}/.config/nvim
	@echo "OK!"

nvim-dependency:
	@echo "Downloading jq ..."
	curl -H "Authorization: ${GITHUB_TOKEN}" -sL ${JQ_LATEST} -o ${HOME}/.local/bin/jq && chmod +x ${HOME}/.local/bin/jq
	@echo "OK!"
	@echo "Downloading yq ..."
	curl -sL ${YQ_LATEST} -o ${HOME}/.local/bin/yq && chmod +x ${HOME}/.local/bin/yq
	@echo "OK!"
	@echo "Downloading nodejs and npm ..."
	curl -sL ${NODEJS_LATEST} | tar xJf - -C ${HOME}/.local/nodejs --strip-components=1
	@echo "OK!"
	@echo "Installing yarn and packages ..."
	export PATH=${PATH}:${HOME}/.local/nodejs/bin && ${HOME}/.local/nodejs/bin/npm install -g yarn
	@echo "Copying .zshrc .bashrc .bash_funcs .bash_alias .bash_exports ..."
	cp -av .zshrc .bashrc .bash_funcs .bash_alias .bash_exports ${HOME}
	@echo "Copying .config/nvim ..."
	cp -av .config/nvim/* ${HOME}/.config/nvim
	@echo "OK!"
	@echo "Installing oh-my-zsh ..."
	rm -rf ~/.oh-my-zsh && git clone https://github.com/ohmyzsh/ohmyzsh.git ~/.oh-my-zsh
	git clone https://github.com/zsh-users/zsh-autosuggestions.git ${HOME}/.oh-my-zsh/custom/plugins/zsh-autosuggestions
	@echo "OK!"

nvim-download:
	@echo "Downloading nvim ..."
	curl -sL ${NVIM_LATEST} | tar xzf - -C ${HOME}/.local/nvim --strip-components=1
	@echo "OK!"

nvim-plugins:
	@echo "Downloading vim-plug ..."
	curl -sfLo ${HOME}/.local/share/nvim/site/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
	@echo "OK!"
	@echo "Installing coc ..."
	cd ${HOME}/.local/share/nvim/site/pack/coc/start && curl -sfL https://github.com/neoclide/coc.nvim/archive/release.tar.gz | tar xzf -
	@echo "OK!"

.PHONY: go

go: go-version go-dir go-download

go-find-version: go-version
	@echo "Finding version ..."
	curl -sL https://golang.org/dl/ | grep -Eo 'go[0-9]{1,2}.[0-9]{1,2}.[0-9]{1,2}.linux-amd64.tar.gz' | grep ${GO_VERSION}

go-dir:
	@echo "Creating directories for go ..."
	mkdir -p ${HOME}/.local/go
	@echo "OK!"

go-download:
	@echo "Downloading go ..."
	curl -sfL ${GO_LATEST} | tar xzf - -C ${HOME}/.local
	@echo "OK!"