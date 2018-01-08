APP_SRC = ./src/main.d ./src/minify.d
TEST_SRC = src/minify.d src/test.d

APP_OUTPUT=bin/dminjs
TEST_OUTPUT=bin/test

all: $(APP_OUTPUT) $(TEST_OUTPUT)

$(APP_OUTPUT): $(APP_SRC)
	dmd $(APP_SRC) -of./$(APP_OUTPUT) -od./bin

release:
	dmd $(APP_SRC) -of./$(APP_OUTPUT) -od./bin -O -inline

$(TEST_OUTPUT): $(TEST_SRC)
	dmd $(TEST_SRC) -of./$(TEST_OUTPUT) -od./bin -unittest
	