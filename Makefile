# $MAKEFILE_LIST : makeが読んだファイルリスト
### includeさレル旅にファイルの名前がMAKE_FILE_LISTに追加される
# $(realpath NAMES...) : NAMESの各要素の絶対パスを取得する#### abspathとは異なり、ファイルやディレクトリが存在するもののみ取得する
# $(dir NAMES...) : NAMES内の各要素のディレクトリを返す
# $(lastword NAMES...) : NAMES内の最後の要素を取得

DOTPATH := $(realpath $(dir $(lastword $(MAKEFILE_LIST))))

# $wildcard : ワイルドカードでパターン指定できる 
CANDIDATES := $(wildcard .??*) bin

EXCLUSIONS := .DS_Store .git .gitmodules .travis.yml

DOTFILES := $(filter-out $(EXCLUSIONS), $(CANDIDATES))

# allターゲットは、make(引数なし）のときに最初に呼ばれるも
## なので、最初にやるべきことを記入することがおおい
all: install

help:
	# @をつけないと、必ず、書いた処理が一度エコーバック出力される
	@echo "make list	#=> Show dot files in this repo"
	@echo "make deploy	#=> Create symlink to home directory"
	@echo "make init	#=> Setup environment settings"
	@echo "make test	#=> Test dotfiles and init scripts"
	@echo "make update	#=> Fetch changes for this repo"
	@echo "make install	#=> Run make update, deploy, init"
	@echo "make clean	#=> Remove the dot files and this repo"

list:
	@$(foreach val, $(DOTFILES), /bin/ls -dF $(val);)

deploy:
	@echo "Copyright (c) 2013-2015 ONUKI All Reights Reserved."
	@echo "==> Start to deploy dotfiles to home directory."
	@echo ""
	@$(foreach val, $(DOTFILES), ln -sfnv $(abspath $(val)) $(HOME)/$(val);)

init:
	@DOTPATH=$(DOTPATH) bash $(DOTPATH)/etc/init/init.sh

test:
	@DOTPATH=$(DOTPAH) bash $(DOTPATH)/etc/test/test.sh

update:
	git pull origin master
	git submodule init  #　これがまだ使い慣れていない
	git submodule update # 同上
	git submodule foreach git pull origin master # 同上

# ターゲット：そのほかのターゲットの組み合わせ　の実行が可能
install: update deploy init
	# $SHELL : 起動に使用しているシェル(ex. /bin/zsh)
	# Makefile内で一般のシェル変数を使用するには、
	  ## $$と二個繋ぎで作成しないといけない
	
	# exec : exec コマンドを使うと、同じプロセスID内で外部コマンドが実行される
	### メリット：余分なプロセスを呼び出さずに済む
	@exec $$SHELL

clean:
	# @実行文：実行するコマンドを表示しない
	# -実行文：実行したコマンドがエラーでもmakeを実行する
	@echo "Remove dot files in your home directory..."
	@-$(foreach val, $(DOTFILES), rm -vrf $(HOME)/$(val);)
	-rm -rf $(DOTPATH)


