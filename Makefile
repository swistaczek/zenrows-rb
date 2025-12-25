.PHONY: install test lint docs build

install:
	bundle install

test:
	bundle exec rake test

lint:
	bundle exec rubocop

docs:
	bundle exec yard doc

build:
	bundle exec rake build
