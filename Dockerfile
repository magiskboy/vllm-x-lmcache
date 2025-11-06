FROM lmcache/vllm-openai:v0.3.9 AS builder

RUN apt-get update -y && \
    apt-get -y install \
    ninja-build \
    pybind11-dev \
    python3.12-dev \
    cmake \
    build-essential \
    pkg-config \
    libaio-dev

RUN . /opt/venv/bin/activate && \
    uv pip install meson pybind11

RUN export LD_LIBRARY_PATH=/usr/local/cuda/compat/lib.real:$LD_LIBRARY_PATH && \
    export NIXL_PLUGIN_DIR=/usr/local/nixl/lib/x86_64-linux-gnu/plugins && \
    git clone https://github.com/ai-dynamo/nixl /workspace/nixl && \
    . /opt/venv/bin/activate && \
    cd /workspace/nixl && \
    rm -rf build && \
    mkdir build && \
    uv run meson setup build/ --prefix=/usr/local/nixl --buildtype=release && \
    cd build && \
    ninja && \
    ninja install && \
    echo "/usr/local/nixl/lib/x86_64-linux-gnu" > /etc/ld.so.conf.d/nixl.conf && \
    echo "/usr/local/nixl/lib/x86_64-linux-gnu/plugins" >> /etc/ld.so.conf.d/nixl.conf && \
    ldconfig && \
    cd /workspace/nixl && \
    uv build --wheel --out-dir /tmp/dist


FROM lmcache/vllm-openai:v0.3.9 AS nixl

COPY --from=builder /tmp/dist/nixl_cu12-0.7.1-cp312-cp312-linux_x86_64.whl /tmp/dist/nixl_cu12-0.7.1-cp312-cp312-linux_x86_64.whl

RUN . /opt/venv/bin/activate && \
    uv pip install /tmp/dist/nixl_cu12-0.7.1-cp312-cp312-linux_x86_64.whl

ENTRYPOINT ["/bin/bash", "-c"]
