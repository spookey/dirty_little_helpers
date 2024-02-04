DIR_VENV	:=	venv

CMD_PIP		:=	$(DIR_VENV)/bin/pip3
CMD_ISORT	:=	$(DIR_VENV)/bin/isort
CMD_BLACK	:=	$(DIR_VENV)/bin/black
CMD_PYLINT	:=	$(DIR_VENV)/bin/pylint

SOURCES		=	$(wildcard */*.py)


.PHONY: help
help:
	@echo "+----------------------+"
	@echo "| development makefile |"
	@echo "+----------------------+"
	@echo
	@echo "isort        run isort"
	@echo "black        run black"
	@echo "pylint       run pylint"
	@echo
	@echo "action       run all"
	@echo
	@echo "clean        drop venv"

.PHONY: clean
clean:
	rm -rfv "$(DIR_VENV)"

$(DIR_VENV):
	python3 -m venv "$(DIR_VENV)"
	$(CMD_PIP) install -U pip

$(CMD_ISORT): $(DIR_VENV)
	$(CMD_PIP) install -U "isort"

$(CMD_BLACK): $(DIR_VENV)
	$(CMD_PIP) install -U "black"

$(CMD_PYLINT): $(DIR_VENV)
	$(CMD_PIP) install -U "pylint"

.PHONY: isort
isort: $(CMD_ISORT)
	$(CMD_ISORT) --profile black --line-length 79 $(SOURCES)

.PHONY: black
black: $(CMD_BLACK)
	$(CMD_BLACK) --line-length 79 $(SOURCES)

.PHONY: pylint
pylint: $(CMD_PYLINT)
	$(CMD_PYLINT) -d C0114,C0115,C0116 --output-format colorized $(SOURCES)

.PHONY: action
action: isort black pylint
