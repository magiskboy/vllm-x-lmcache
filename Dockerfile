FROM lmcache/vllm-openai:nightly-2025-11-05

RUN ls

ENTRYPOINT ["/bin/sh", "-c"]
