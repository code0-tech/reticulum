ARG PYTHON_VERSION=3.12
ARG UV_VERSION=0.11.16

FROM ghcr.io/astral-sh/uv:${UV_VERSION} AS uv
FROM python:${PYTHON_VERSION}-slim

COPY --from=uv /uv /uvx /usr/local/bin/

WORKDIR /velorum

COPY projects/velorum/pyproject.toml projects/velorum/uv.lock ./
RUN uv sync --frozen
COPY projects/velorum/src/model.py ./src/model.py
RUN uv run python -c "from src.model import load_vector_model; load_vector_model()"

COPY projects/velorum/cli ./cli
COPY projects/velorum/src ./src
COPY projects/velorum/main.py ./main.py

ENV HF_HUB_OFFLINE=1
ENV PYTHONUNBUFFERED=1

HEALTHCHECK --interval=5s --timeout=3s --retries=3 \
  CMD uv run python -c "import grpc; from grpc_health.v1 import health_pb2, health_pb2_grpc; ch = grpc.insecure_channel('localhost:50051'); stub = health_pb2_grpc.HealthStub(ch); stub.Check(health_pb2.HealthCheckRequest(service='liveness'))" || exit 1

EXPOSE 50051
CMD ["uv", "run", "main.py"]
