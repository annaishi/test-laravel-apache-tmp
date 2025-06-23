### development
.PHONY: clear
clear:
	docker compose exec -it app php artisan cache:clear
	docker compose exec -it app php artisan config:clear
	docker compose exec -it app php artisan route:clear
	docker compose exec -it app php artisan view:clear

.PHONY: up
up:
	mkdir -p ./laravel/node_modules
	docker compose up -d

.PHONY: down
down:
	docker compose down

.PHONY: stop
stop:
	docker compose stop

# git clone直後の状態からアプリケーション起動まで(env修正のみ手動)
.PHONY: init
init:
	cp ./laravel/.env.example ./laravel/.env
	docker compose build --no-cache
	make up
	docker compose exec -it app composer install
	docker compose exec -it app php artisan key:generate
	docker compose exec -it app php artisan migrate:fresh --seed

# git clone直後の状態に戻す
.PHONY: destroy
destroy:
	docker compose down --rmi all --volumes --remove-orphans
	rm -rf laravel/vendor
	rm -rf laravel/node_modules
	rm -rf laravel/public/build
	rm -rf laravel/public/hot
	rm -rf laravel/public/storage

.PHONY: reset
reset:
	make destroy
	make init

# pullしてきたとき
# make init

### app-create(laravelプロジェクト作成)
.PHONY: app-create
app-create:
	rm -rf laravel
	mkdir -p laravel
	docker build -t app-image ./infra/development/php --no-cache
	docker run -d --name app-container -it --mount type=bind,source=$(shell pwd)/laravel,target=/var/www/work -p 9000:9000 app-image
	docker exec -it app-container composer create-project laravel/laravel .
	docker stop app-container
	docker rm app-container
	docker rmi app-image

# laravelプロジェクト作成備忘録
# infra/, .dockerignore, .gitignore, docker-compose.yml, Makefile, README.mdでスタート
# .dockerignoreのvue/node_modulesをコメントアウトされてるのを確認
# make app-create
# create laravelするときに手動確認あるかも
# プロジェクト名は.(カレントディレクトリ)を指定(聞かれた場合のみ)
# .env(.sample,.production)ファイルの中身をさ作成&修正
# vite.config.jsでサーバーオプションのhost:trueを指定
# .dockerignoreのvue/node_modulesをコメントアウトを解除する
# make reset

### front-create(vue導入)
.PHONY: front-create
front-create:
	docker compose exec -it vite npm install --save-dev @vitejs/plugin-vue
	docker compose exec -it vite npm install --save-dev vue-router@4
	docker compose exec -it vite npm install --save-dev pinia
	docker compose exec -it vite npm install --save-dev sass

# vue導入の備忘録
# laravelは動いている状態でスタート
# make front-create
# create vueするときに手動確認あり
# vite.config.jsでpluginにvueを追加
# vite.config.jsでsesolve.alias.vue: "vue/dist/vue.esm-bundler.js"(ランタイムに加えてコンパイラも含むやつ)を必要に応じて指定
# (DOM内テンプレートを有効にする場合、主に1blade1vue運用でblade内でデータを受け渡す場合を想定)
# (ルートコンポーネントをvueにする場合は不要、この場合は無理やりデータの受け渡しをするか、完全なspaに近い形でのvue側でのルーティングやAPIでのデータ取得が必要になってくる(middlewareはwebだけど))
# パターン0:#appにルートコンポーネントAppをマウントさせ、子コンポーネントにRouterViewを用い、vue-routerでpagesのcomponentの登録をしてデータは全てAPI取得(router.jsでの登録)
# パターン1:vue-routerでpagesのcomponentの登録をしてroute情報を無理やり渡す(router.jsでの登録)
# パターン1-2:vue-routerでpagesのcomponentの登録をしてデータをDOM内テンプレートでRouterViewコンポーネントのslotに入ってるコンポーネントにpropsで渡す(router.jsでの登録)
# パターン2:ルートコンポーネントにpagesのcomponentを大量に登録してDOM内テンプレート(実質1blade1vue)(main.jsでの登録)
# パターン3:複数マウント&DOM内テンプレート(1blade1vue)(main.jsでの登録)
# 結局vueからAPI叩いてデータ取得する形になるからSSRチックなパターン1-2がよさげかも(仮想DOMのままだけど初回描画の遅延は発生しなさそう？)？
# SSRは別の実現方法があるので今回はパターン0で
# make reset



### production
.PHONY: prod-up
prod-up:
	docker compose -f docker-compose-prod.yml up -d

.PHONY: prod-init
prod-init:
	cp ./laravel/.env.production ./laravel/.env
	docker compose -f docker-compose-prod.yml build --no-cache
	make prod-up
	docker compose -f docker-compose-prod.yml exec -it app php artisan migrate:fresh --seed

.PHONY: prod-down
prod-down:
	docker compose -f docker-compose-prod.yml down --rmi all --volumes --remove-orphans

# ローカルでの本番環境構築
# make destroy
# 一応envは確認しておく
# make production-init
#
# 終了時
# make production-down
# make destroy