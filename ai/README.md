# Ansible Collection - tenx.ai

AI inference infrastructure: NVIDIA GPU bring-up and vLLM model serving.

## Roles

- **[nvidia_driver](roles/nvidia_driver/README.md)** — installs the
  recommended NVIDIA server driver via `ubuntu-drivers install --gpgpu`
  (reboots to load it); no-op when `nvidia-smi` already works.
- **[vllm](roles/vllm/README.md)** — pinned vLLM in a uv virtualenv,
  systemd service exposing an OpenAI-compatible API, secrets via env file,
  health gate, optional Datadog OpenMetrics check.

## Playbooks

- `tenx.ai.vllm` — applies both roles to `role__inference` hosts (the
  Latitude tag group; override with `-e target_hosts=...`).

## Semaphore setup

Environment secrets (environment-variables section): `HF_TOKEN` (only for
gated/private models), `VLLM_API_KEY` (optional client auth). Model
selection lives in inventory group_vars — see the playbooks repository.
