GIT_TAG := $(shell git describe --abbrev=0 --tags)
SHA := $(shell git rev-parse --short=8 HEAD)

# 建立 network
create-network:
	docker network create my_network

# 建立 mysql volume
create-mysql-volume:
	docker volume create mysql

# 啟動 mysql
create-mysql:
	docker-compose -f mysql.yml up -d

# 啟動 rabbitmq
create-rabbitmq:
	docker-compose -f rabbitmq.yml up -d

# 安裝環境
install-python-env:
	pipenv sync

# 啟動 celery, 專門執行 twse queue 列隊的任務，
run-celery-twse:
	pipenv run celery -A financialdata.tasks.worker worker --loglevel=info --concurrency=1  --hostname=%h -Q twse

# 啟動 celery, 專門執行 tpex queue 列隊的任務，
run-celery-tpex:
	pipenv run celery -A financialdata.tasks.worker worker --loglevel=info --concurrency=1  --hostname=%h -Q tpex

# sent task
sent-taiwan-stock-price-task:
	pipenv run python financialdata/producer.py taiwan_stock_price 2021-04-01 2021-04-12

# 建立 dev 環境變數
gen-dev-env-variable:
	python genenv.py

# 建立 staging 環境變數
gen-staging-env-variable:
	VERSION=STAGING python genenv.py

# 建立 release 環境變數
gen-release-env-variable:
	VERSION=RELEASE python genenv.py

# 建立 docker image
build-image:
	docker build -f Dockerfile -t linsamtw/crawler:${GIT_TAG} .

# 推送 image
push-image:
	docker push linsamtw/crawler:${GIT_TAG}
	
# 啟動 crawler celery
up-crawler:
	docker-compose -f crawler.yml up

# 啟動多個 crawler celery
up-multi-crawler:
	docker-compose -f crawler_multi_celery.yml up

# 啟動 scheduler
up-scheduler:
	docker-compose -f scheduler.yml up

# 執行 scheduler
run-scheduler:
	pipenv run python financialdata/scheduler.py

# 測試覆蓋率
test-cov:
	pipenv run pytest --cov-report term-missing --cov-config=.coveragerc --cov=./financialdata/ tests/

# 部屬爬蟲
deploy-crawler:
	GIT_TAG=${GIT_TAG} docker stack deploy --with-registry-auth -c crawler.yml financialdata

# 部屬 scheduler
deploy-scheduler:
	GIT_TAG=${GIT_TAG} docker stack deploy --with-registry-auth -c scheduler.yml financialdata

# format
format:
	black -l 80 financialdata tests

register-shell-runner:
	sudo gitlab-runner register --non-interactive --url "https://gitlab.com/" --registration-token "gbH8b8CrdU3UA7xuRumE" --executor "shell" --description "build_image" --tag-list "build_image"

register-docker-runner:
	sudo gitlab-runner register --non-interactive --url "https://gitlab.com/" --registration-token "gbH8b8CrdU3UA7xuRumE" --executor "docker" --docker-image continuumio/miniconda3:4.3.27 --description "docker-runner" --tag-list "docker-runner"
