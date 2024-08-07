
FROM python:3.10-slim as python-base

ENV PYTHONUNBUFFERED = 1 \
    PYTHONDONTWRITEBYTECODE = 1 \
    PIP_NO_CACHE_DIR = off \
    PIP_DISABLE_PIP_VERSION_CHECK = on \
    PIP_DEFAULT_TIMEOUT = 100 \
    POETRY_VERSION = 1.1.14 \
    POETRY_HOME = "/opt/poetry" \
    POETRY_VIRTUALENVS_IN_PROJECT = true \
    POETRY_NO_INTERACTION = 1 \
    PYSETUP_PATH = "/opt/pysetup" \
    VENV_PATH = "/opt/pysetup/.venv"

ENV PATH = "$POETRY_HOME/bin:$VENV_PATH/bin:$PATH"


FROM python-base as dev-base

RUN : \
    && apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    --no-install-recommends \
    curl \
    build-essential \
    libsndfile1 \
    libsndfile1-dev

ENV GET_POETRY_IGNORE_DEPRECATION=1

RUN curl -sSL https://raw.githubusercontent.com/python-poetry/poetry/master/get-poetry.py \
    | POETRY_VERSION=1.1.14 python

ENV PATH="${PATH}:/root/.poetry/bin"

COPY poetry.lock pyproject.toml ./

RUN poetry install


FROM python-base as production

COPY --from=dev-base $PYSETUP_PATH $PYSETUP_PATH

COPY . /app

EXPOSE $PORT

CMD gunicorn --workers=4 --bind 0.0.0.0:$PORT app:app