SRC = ./src/main.d ./src/minify.d
TEST_SRC = src/minify.d src/test.d

all: bin/dminjs bin/test

bin/dminjs: $(SRC)
	dmd $(SRC) -of./bin/dminjs -od./bin -unittest

release:
	dmd $(SRC) -of./bin/dminjs -od./bin -O -inline
	
test:
	./bin/dminjs ./tests/test.js > ./tests/test.min.js

bin/test: $(TEST_SRC)
	dmd src/minify.d src/test.d -of./bin/test -od./bin -unittest
	