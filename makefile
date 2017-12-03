SRC = ./src/main.d ./src/minify.d

all: dev

dev: $(SRC)
	dmd $(SRC) -of./bin/dminjs -od./bin -unittest

release:
	dmd $(SRC) -of./bin/dminjs -od./bin -O -inline
	
test:
	./bin/dminjs ./tests/test.js > ./tests/test.min.js