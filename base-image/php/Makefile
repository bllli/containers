export BUILDAH_LAYERS=true

TAG := $(shell git describe --abbrev=0 --tags)

PHP8_VERSION := 8.1.11

PHP7_VERSION := 7.4.27

CADDY_VERSION := 2.6.1

COMPOSER ?= COMPOSER_MEMORY_LIMIT=-1 composer

IMAGE_NAME_BENCODE := php-ext-bencode:$(PHP8_VERSION)-fpm-bullseye

IMAGE_NAME_BENCODE_PHP7 := php-ext-bencode:$(PHP7_VERSION)-fpm-bullseye

IMAGE_NAME_CADDY := caddy-ext:$(CADDY_VERSION)

IMAGE_NAME_PHP8 := phpfpm-caddy:$(PHP8_VERSION)-$(TAG)

IMAGE_NAME_PHP7 := phpfpm-caddy:$(PHP7_VERSION)-$(TAG)


.PHONY: help

default: help

help:
	@grep -E '^[a-zA-Z_-]+:.*?##.*$$' $(MAKEFILE_LIST) | sort | awk '{split($$0, a, ":"); printf "\033[36m%-30s\033[0m %-30s %s\n", a[1], a[2], a[3]}'
	sudo echo BUILDAH_LAYERS=$$BUILDAH_LAYERS

caddy:
	sudo buildah bud --network host -t $(IMAGE_NAME_CADDY) -f caddy2.Dockerfile

php8/bencode:
	sudo buildah bud --network host --build-arg PHP_VER_TAG=$(PHP8_VERSION)-fpm-bullseye -t $(IMAGE_NAME_BENCODE) -f bencode.Dockerfile

php7/bencode:
	sudo buildah bud --network host --build-arg PHP_VER_TAG=$(PHP7_VERSION)-fpm-bullseye -t $(IMAGE_NAME_BENCODE_PHP7) -f bencode.Dockerfile

php8/php:
	sudo buildah bud --network host --build-arg PHP_VER_TAG=$(PHP8_VERSION)-fpm-bullseye --build-arg PHP_EXT_BENCODE_VERSION=$(PHP8_VERSION)-fpm-bullseye -t $(IMAGE_NAME_PHP8) -f php8.Dockerfile

php7/php:
	sudo buildah bud --network host --build-arg PHP_VER_TAG=$(PHP7_VERSION)-fpm-bullseye --build-arg PHP_EXT_BENCODE_VERSION=$(PHP7_VERSION)-fpm-bullseye -t $(IMAGE_NAME_PHP7) -f php8.Dockerfile
