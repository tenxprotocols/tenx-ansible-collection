# tenx.ai.vllm

Serves a HuggingFace model with [vLLM](https://docs.vllm.ai/) as an
OpenAI-compatible API: pinned vLLM in a `uv`-managed virtualenv, dedicated
system user, systemd service, secrets via a root-only environment file, a
post-start health gate, and an optional Datadog OpenMetrics check.

Requires a working NVIDIA driver — run [tenx.ai.nvidia_driver](../nvidia_driver/README.md)
first (the collection playbook `tenx.ai.vllm` does both).

## Sizing the model to the GPU

`vllm_model` must fit the card. Reference point: Qwen3-Coder-Next (80B MoE,
3B active) on a single H100 80GB requires an AWQ INT4 build (~46 GB weights,
e.g. `bullpoint/Qwen3-Coder-Next-AWQ-4bit`); BF16 (~160 GB) and FP8 (~90 GB)
do not fit. Set `vllm_min_vram_gb` so a wrong pairing fails in seconds
instead of an OOM loop.

## Variables

| Variable | Default | Description |
|---|---|---|
| `vllm_model` | — (required) | HuggingFace repo to serve |
| `vllm_served_model_name` | repo basename | model name on the API |
| `vllm_version` | `0.25.1` | vLLM version pinned into the venv |
| `vllm_python_version` | `3.12` | venv Python (uv downloads it if needed) |
| `vllm_host` / `vllm_port` | `0.0.0.0` / `8000` | API bind address |
| `vllm_max_model_len` | `131072` | context length |
| `vllm_gpu_memory_utilization` | `0.92` | fraction of VRAM vLLM may use |
| `vllm_tensor_parallel_size` | `1` | GPUs to shard across |
| `vllm_enable_auto_tool_choice` | `true` | enable tool calling |
| `vllm_tool_call_parser` | `qwen3_coder` | parser matching the model family |
| `vllm_extra_args` | `[]` | extra `vllm serve` flags |
| `vllm_extra_env` | `{}` | extra env vars for the service (e.g. `VLLM_USE_FLASHINFER_SAMPLER: "0"`) |
| `vllm_hf_token` | `$HF_TOKEN` | HF token (gated/private models only) |
| `vllm_api_key` | `$VLLM_API_KEY` | if set, required as Bearer token |
| `vllm_hf_home` | `/opt/vllm/huggingface` | model cache (needs tens of GB) |
| `vllm_min_vram_gb` | `0` (off) | preflight VRAM assertion |
| `vllm_health_timeout` | `1800` | seconds to wait for `/health` |
| `vllm_datadog_check` | `true` | scrape `/metrics` via Datadog OpenMetrics |

Secrets follow the fleet convention: supply `HF_TOKEN` / `VLLM_API_KEY` as
Semaphore Environment secrets (environment-variables section). They are
written to a `0640` env file, never to the unit's command line.

## Example

```yaml
- hosts: role__inference
  become: true
  roles:
    - role: tenx.ai.nvidia_driver
    - role: tenx.ai.vllm
      vars:
        vllm_model: bullpoint/Qwen3-Coder-Next-AWQ-4bit
        vllm_served_model_name: qwen-3-coder-next
        vllm_min_vram_gb: 70
```
