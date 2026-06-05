# Enodios

**Hermes of the road** — one-script Linux setup for self-hosted [Hermes Agent](https://github.com/NousResearch/hermes-agent) + [vLLM](https://github.com/vllm-project/vllm).

Enodios (Ἐνόδιος) is an epithet of Hermes: god of roads, travelers, and crossroads. This project is the guide between your agent and local GPU inference.

## Quick start

```bash
curl -fsSL https://raw.githubusercontent.com/DataKnifeAI/enodios/main/install.sh | bash
enodios install    # vLLM venv + dependencies (first run downloads ~2GB)
enodios doctor     # GPU, CUDA, ports
enodios start      # vLLM with Hermes 3 AWQ (foreground)
enodios configure  # point ~/.hermes/config.yaml at vLLM
hermes chat
```

## Requirements

- Linux + NVIDIA GPU (tested on RTX 4090)
- ~8GB free VRAM for default AWQ model (close other GPU apps)
- Python 3.12 managed via [uv](https://github.com/astral-sh/uv) (installed automatically)

## Commands

| Command | Description |
|---------|-------------|
| `install` | Create venv, install vLLM, link CLI |
| `start` | Run vLLM server (Hermes 3, tool calling) |
| `stop` | Stop vLLM processes started by enodios |
| `doctor` | Check GPU, CUDA toolkit, ports, venv |
| `bench` | Tool-call latency smoke test |
| `configure` | Wire Hermes to `http://127.0.0.1:8000/v1` |
| `status` | Show whether vLLM is responding |

## Defaults

| Setting | Value |
|---------|-------|
| Model | `solidrust/Hermes-3-Llama-3.1-8B-AWQ` |
| Served name | `hermes3:8b` |
| Port | `8000` |
| Context | `16384` |
| Venv | `~/.local/share/enodios/.venv` |

Override via environment: `ENODIOS_PORT`, `ENODIOS_MODEL`, `ENODIOS_GPU_UTIL`, `ENODIOS_MAX_MODEL_LEN`.

## Optional: FlashInfer speedup

If CUDA toolkit is installed (`/opt/cuda/bin/nvcc`):

```bash
export CUDA_HOME=/opt/cuda
export PATH="$CUDA_HOME/bin:$PATH"
# then remove VLLM_USE_FLASHINFER_SAMPLER=0 from start (future enodios release)
```

## License

MIT
