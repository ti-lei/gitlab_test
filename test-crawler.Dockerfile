# 在 local 端測試 CI 步驟
FROM continuumio/miniconda3:4.3.27

COPY . /opt/

RUN pip install pipenv
RUN pipenv sync
RUN python3 genenv.py
RUN pipenv run pytest --cov-report term-missing --cov-config=.coveragerc --cov=./financialdata/ tests/
