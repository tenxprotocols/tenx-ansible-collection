# tenx.ai.nvidia_driver

Installs the recommended NVIDIA server driver via `ubuntu-drivers install
--gpgpu` and reboots the host to load it. Skips everything if `nvidia-smi`
already works, and fails fast if the host has no NVIDIA GPU on the PCI bus.

| Variable | Default | Description |
|---|---|---|
| `nvidia_driver_allow_reboot` | `true` | reboot after installing (required to load the driver) |
| `nvidia_driver_reboot_timeout` | `900` | seconds to wait for the host to return |
