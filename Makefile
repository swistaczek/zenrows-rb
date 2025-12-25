.PHONY: install test lint rbs docs build

install:
	bundle install

test:
	bundle exec rake test

lint:
	bundle exec rubocop

rbs:
	rbs -I sig -r monitor -r openssl -r logger validate

docs:
	bundle exec yard doc

build:
	bundle exec rake build
