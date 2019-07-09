.PHONY: all lint test coverage

all: lint test

lint:
	vint autoload plugin
	vimlparser plugin/*/*.vim autoload/*/*.vim > /dev/null

test:
	rake test

coverage:
	mkdir -p build
	rm -f ./build/coverage.xml ./build/profile.txt ./build/.coverage.covimerage
	PROFILE_LOG=./build/profile.txt rake test
	covimerage write_coverage ./build/profile.txt --data-file ./build/.coverage.covimerage
	coverage xml -o ./build/coverage.xml
	coverage report
