# Enodios

**Ἐνόδιος — Hermes of the road.** One-script Linux setup to run [Hermes Agent](https://github.com/NousResearch/hermes-agent) on **your own GPU** via [vLLM](https://github.com/vllm-project/vllm).

No cloud API keys for inference. Fast tool calling. Uncensored agent models.

**Documentation site:** https://dataknifeai.github.io/enodios/

---

## What it does

```
You ──► Hermes Agent (tools, files, terminal, web)
              │
              │  OpenAI-compatible API
              ▼
         vLLM on your GPU (Hermes 3, tool-call parser)
```

Enodios installs and wires the stack:

1. **vLLM** — high-throughput local inference on NVIDIA GPUs (native, no Docker required)
2. **Hermes Agent** — agentic CLI you already use; pointed at `http://127.0.0.1:8000/v1`
3. **Defaults tuned for agent work** — AWQ Hermes 3 8B, `--tool-call-parser hermes`, **64k context** (Hermes minimum)

Benchmarked on RTX 4090: **~2s tool-call latency** (vLLM) vs **~7s** (Ollama) for the same model class.

---

## Requirements

### Hardware

| Component | Minimum | Recommended |
|-----------|---------|-------------|
| **GPU** | NVIDIA, 12GB+ VRAM | RTX 3090/4080/4090 (24GB) |
| **Free VRAM** | ~14GB (AWQ 8B + 64k KV) | ~18GB+ with desktop/apps open |
| **RAM** | 16GB | 32GB+ |
| **Disk** | 15GB free | 30GB+ (model cache + vLLM venv) |

### Software

| Requirement | Notes |
|-------------|-------|
| **Linux** | x86_64. Arch, Ubuntu, Fedora, etc. |
| **NVIDIA driver** | `nvidia-smi` must work |
| **curl, git** | For bootstrap |
| **Hermes Agent** | [Install separately](https://github.com/NousResearch/hermes-agent) if not already present |
| **Python 3.12** | Installed automatically via `uv` — system Python 3.14+ is not used |
| **CUDA toolkit** | Optional (`pacman -S cuda` / `nvidia-cuda-toolkit`). Speeds up sampling; not required |

### What Enodios installs for you

- [uv](https://github.com/astral-sh/uv) — Python environment manager
- **vLLM** + PyTorch CUDA wheels in `~/.local/share/enodios/.venv`
- **`enodios` CLI** → `~/.local/bin/enodios`

### Network

- **HuggingFace** access for first model download (no token needed for public AWQ weights)
- **No** ongoing cloud inference dependency

---

## Quick start (5 minutes)

### 1. Install Hermes Agent (if needed)

```bash
curl -fsSL https://raw.githubusercontent.com/NousResearch/hermes-agent/main/scripts/install.sh | bash
hermes setup
```

On first run, choose **Full setup** (not Quick Setup / Nous Portal). When you reach **Inference Provider**, pick **Custom endpoint (enter URL manually)** and use the [wizard values below](#connect-hermes-via-cli-wizard).

### 2. Install Enodios + vLLM

```bash
curl -fsSL https://raw.githubusercontent.com/DataKnifeAI/enodios/main/install.sh | bash
enodios install
```

First `install` downloads ~2GB of Python wheels. Subsequent runs are fast.

**Update later:**

```bash
enodios update
```

Pulls the latest enodios from git, refreshes `~/.local/bin/enodios`, and upgrades vLLM in the venv. Restart vLLM if it was running: `enodios stop && enodios start -b`.

`enodios start` checks for updates (git fetch every 6h by default) and prints a notice when a newer release is available.

### 3. Verify GPU + get tuned settings

```bash
enodios recommend    # detect VRAM → suggested ENODIOS_* exports
enodios doctor
```

Expect:

- `nvidia-smi` shows your GPU
- `torch ... cuda True`
- `OK: .../enodios/.venv/bin/vllm`

Optional: persist recommendations:

```bash
enodios recommend --apply
source ~/.local/share/enodios/recommended.env
```

### 4. Start inference

```bash
enodios start -b     # background (logs: ~/.local/share/enodios/vllm.log)
```

vLLM binds **127.0.0.1** by default (loopback only). Wait until ready (30–90s first time), then:

```bash
enodios status
enodios bench
```

Foreground instead: `enodios start` (Ctrl+C to stop).

### 5. Wire Hermes

**Option A — setup wizard (recommended during install):**

```bash
hermes setup
# → Full setup
# → Inference Provider
# → Custom endpoint (enter URL manually)
```

Already configured Hermes? Jump to provider only:

```bash
hermes setup model
# or: hermes model
```

Use these values when prompted:

| Prompt | Value |
|--------|-------|
| Provider | **Custom endpoint (self-hosted / VLLM / etc.)** |
| Base URL | `http://127.0.0.1:8000/v1` |
| API key | Leave empty (Enodios has no auth by default) |
| Model name | `hermes3:8b` |
| Context length | `65536` (Hermes agent minimum) |
| Provider name (if asked) | `enodios` |

Then verify and chat:

```bash
hermes config show
hermes chat
```

**Option B — automatic (overwrites provider block):**

```bash
enodios configure
hermes chat
```

See [Connect Hermes via CLI wizard](#connect-hermes-via-cli-wizard) for remote GPU hosts, named providers, and troubleshooting.

### 6. Stop when done

```bash
enodios stop
```

---

## Connect Hermes via CLI wizard

### Setup path (first install)

```bash
hermes setup
```

1. **How would you like to set up Hermes?** → **Full setup** — configure every provider, tool & option yourself  
   (Skip **Quick Setup (Nous Portal)** — that's cloud, not local Enodios.)
2. Wizard runs sections in order. At **Inference Provider** → choose **Custom endpoint (enter URL manually)**.
3. Enter the Enodios values in the table below.
4. You can press Enter through later sections (terminal, gateway, tools) or configure them later.

Shortcut to provider only (skip the full wizard):

```bash
hermes setup model
```

Same **Inference Provider** → **Custom endpoint** flow as step 2 above.

### `hermes model` vs `/model`

| Command | Where | Purpose |
|---------|-------|---------|
| **`hermes setup`** → Full setup → Inference Provider | Install / reconfigure | Full wizard; Enodios at first provider step |
| **`hermes setup model`** / **`hermes model`** | Your shell (outside chat) | Provider picker only — same Custom endpoint flow |
| **`/model`** | Inside `hermes chat` | Switch between **already configured** providers only |

To add Enodios/vLLM for the first time, use **`hermes setup`** (Full setup) or **`hermes setup model`**, not `/model`.

### Prerequisites

1. Hermes Agent installed: `hermes setup` (first time only)
2. Enodios vLLM running and healthy:

```bash
enodios start -b
enodios status    # should list hermes3:8b
enodios bench     # tool-call smoke test
```

### Wizard walkthrough (same machine)

Exit any active `hermes chat` session first (`Ctrl+C` or `/quit`).

**From full setup:**

```bash
hermes setup
# Full setup → Inference Provider → Custom endpoint (enter URL manually)
```

**Or provider only:**

```bash
hermes setup model
# Custom endpoint (enter URL manually)
```

Step through the prompts:

```
1. Inference Provider (full setup) or provider list (hermes model)
   → Custom endpoint (enter URL manually)

2. API base URL
   → http://127.0.0.1:8000/v1
     (must end with /v1 — same as enodios urls → local)

3. API key
   → Press Enter / skip
     (loopback Enodios has no API key unless you added --api-key to vLLM)

4. Model name
   → hermes3:8b
     (Enodios served name — NOT the HuggingFace path)

5. Context length
   → 65536
     (required for Hermes agent tool loops; matches enodios default)

6. Named provider (if prompted)
   → enodios
     (enables provider: custom:enodios in config)
```

Hermes may probe `http://127.0.0.1:8000/v1/models` to validate the endpoint. If vLLM is still loading, wait and re-run `hermes setup model` or `hermes model`.

### Verify configuration

```bash
hermes config show
```

Expect something like:

```yaml
model:
  default: hermes3:8b
  provider: custom:enodios
  context_length: 65536
custom_providers:
  - name: enodios
    base_url: http://127.0.0.1:8000/v1
    models:
      hermes3:8b:
        context_length: 65536
```

Start chatting:

```bash
hermes chat
# or
hermes
```

Inside an existing session, switch back to Enodios with:

```
/model custom:enodios:hermes3:8b
# or, if only one model on the endpoint:
/model custom:enodios
```

### Remote GPU host (distributed Hermes)

On the **GPU machine**:

```bash
enodios start -b --lan
enodios urls    # note the lan: URL, e.g. http://192.168.1.10:8000/v1
```

On the **controller** (where you run Hermes):

```bash
hermes setup model
```

| Prompt | Value |
|--------|-------|
| Provider | Custom endpoint (enter URL manually) |
| Base URL | `http://<gpu-host-ip>:8000/v1` from `enodios urls` |
| API key | Empty |
| Model | `hermes3:8b` |
| Context length | `65536` |
| Provider name | `enodios` |

Or skip the wizard on the controller:

```bash
enodios configure --url http://<gpu-host-ip>:8000/v1
```

### Wizard vs `enodios configure`

| Method | Best for |
|--------|----------|
| **`hermes setup`** (Full setup) | First install — Inference Provider → Custom |
| **`hermes setup model`** / **`hermes model`** | Reconfigure provider only |
| **`enodios configure`** | Quick overwrite of Hermes config for the Enodios endpoint only |
| **`enodios configure --url`** | Controller machine pointing at a remote GPU host |

Both persist to `~/.hermes/config.yaml`. `enodios configure` creates a timestamped backup before editing.

### Troubleshooting the wizard

| Problem | Fix |
|---------|-----|
| Endpoint probe fails | `enodios status` — wait for model load; check `tail -f ~/.local/share/enodios/vllm.log` |
| Wrong model name | Use `hermes3:8b` (run `enodios status` to confirm) |
| Context too small | Set **65536** explicitly in the wizard |
| No tool calls in chat | `enodios bench` must pass; Enodios sets `--tool-call-parser hermes` automatically |
| `/model` missing Enodios | Exit chat; run `hermes setup model` first — `/model` only lists configured providers |
| Picked Quick Setup by mistake | Re-run `hermes setup` → **Full setup** → Inference Provider → Custom |
| Remote host unreachable | GPU host: `enodios start --lan` + `enodios firewall --allow` (or accept prompt on `start --lan`) |

---

## Commands

| Command | Description |
|---------|-------------|
| `enodios install` | Create venv, install vLLM, link CLI |
| `enodios update` | `git pull` + upgrade vLLM + refresh CLI link |
| `enodios recommend` | Detect GPU VRAM → model/settings for Hermes |
| `enodios recommend --apply` | Write `~/.local/share/enodios/recommended.env` |
| `enodios start` | Run vLLM foreground on loopback |
| `enodios start -b` | Background; log + PID under `~/.local/share/enodios/` |
| `enodios start --lan` | Bind `0.0.0.0` for LAN access; prompts to open firewall |
| `enodios firewall` | Check whether LAN clients can reach port 8000 |
| `enodios firewall --allow` | Add UFW/firewalld rule without prompting |
| `enodios stop` | Stop vLLM for this stack |
| `enodios urls` | Print local + LAN API URLs |
| `enodios doctor` | GPU, CUDA, venv, endpoint health |
| `enodios bench` | Tool-call latency smoke test |
| `enodios configure` | Point Hermes at `http://127.0.0.1:8000/v1` |
| `enodios configure --url URL` | Point Hermes at a remote vLLM endpoint |
| `enodios status` | Query `/v1/models` + URLs |

---

## Distributed Hermes (Hermes controlling Hermes)

Run vLLM on a GPU host; run the orchestrating Hermes agent on another machine on the same LAN.

**GPU host** (inference server):

```bash
enodios start -b --lan
enodios urls    # copy the LAN URL
```

**Controller** (Hermes agent with tools):

```bash
enodios configure --url http://<gpu-host>:8000/v1
hermes chat
```

vLLM has **no API authentication**. Use `--lan` only on a trusted local network.

---

## Defaults

| Setting | Value |
|---------|-------|
| Model weights | `solidrust/Hermes-3-Llama-3.1-8B-AWQ` |
| API model name | `hermes3:8b` |
| Bind address | `127.0.0.1` (loopback; use `start --lan` for LAN) |
| Port | `8000` |
| Context length | `65536` (Hermes agent minimum) |
| KV cache | `fp8` |
| GPU memory cap | `75%` of VRAM |
| Venv | `~/.local/share/enodios/.venv` |
| Background log | `~/.local/share/enodios/vllm.log` |

### Environment overrides

```bash
export ENODIOS_PORT=8000
export ENODIOS_MODEL=solidrust/Hermes-3-Llama-3.1-8B-AWQ
export ENODIOS_GPU_UTIL=0.85        # if GPU is idle
export ENODIOS_MAX_MODEL_LEN=65536  # default; lower only if VRAM OOM
export ENODIOS_KV_CACHE_DTYPE=fp8   # set auto if quality issues
export ENODIOS_VENV=$HOME/.local/share/enodios/.venv
export ENODIOS_LOG=$HOME/.local/share/enodios/vllm.log
```

---

## Recommended models (Hermes Agent + tools + uncensored)

| Model | VRAM | Tools | Uncensored | Notes |
|-------|------|-------|------------|-------|
| **Hermes 3 8B AWQ** (default) | ~20GB @ 64k | ✅ | ✅ | Best balance; enodios default |
| `NousResearch/Hermes-3-Llama-3.1-8B` (BF16) | ~16GB+ weights | ✅ | ✅ | Higher quality; needs free VRAM |
| `vatistasdim/Cipher-Abliterated` | ~4GB | ✅ | ✅ | Fastest; smaller model |
| Ollama `hermes3:8b` | ~5GB weights | ✅ | ✅ | Fallback; slower than vLLM |

Aligned models (censored) with strong tools: `nemotron-3-nano`, `qwen3.6` — use Ollama or vLLM separately if you prefer those.

---

## Troubleshooting

### `Free memory ... less than desired GPU memory utilization`

64k context uses **~20GB VRAM** on a 4090. Close games, Ollama, etc. before starting.

```bash
enodios stop
# close GPU-heavy apps, then:
enodios start
# or lower cap if needed:
export ENODIOS_GPU_UTIL=0.65
enodios start
```

Enodios uses `--kv-cache-dtype fp8` by default to fit 64k on 24GB cards. Disable with `ENODIOS_KV_CACHE_DTYPE=auto` if you hit quality issues.

### `Could not find nvcc`

Harmless with default settings. Enodios uses PyTorch sampler fallback. For optional speedup:

```bash
# Arch/CachyOS example
sudo pacman -S cuda
export CUDA_HOME=/opt/cuda
export PATH="$CUDA_HOME/bin:$PATH"
```

### `vLLM not running on port 8000`

```bash
enodios start -b
tail -f ~/.local/share/enodios/vllm.log
# or check conflict:
ss -ltnp | grep 8000
```

### Remote Hermes cannot reach vLLM

GPU host must use LAN mode; controller needs the LAN URL:

```bash
# on GPU host
enodios start -b --lan
enodios urls

# on controller
enodios configure --url http://<gpu-host>:8000/v1
```

On the GPU host, `enodios start --lan` detects UFW/firewalld and asks to allow TCP `8000` for your LAN subnet. Or run `enodios firewall --allow` manually.

### Hermes connects but no tool calls

Ensure vLLM started with Hermes parser (enodios does this automatically):

```bash
--enable-auto-tool-choice --tool-call-parser hermes
```

### Docker vLLM / NIM `CUDA_ERROR_UNKNOWN`

Use **native** enodios (host vLLM). This path avoids Docker CUDA issues seen on some setups.

---

## Architecture

**Single machine** (default):

```mermaid
flowchart LR
  U[You] --> H[Hermes Agent CLI]
  H -->|127.0.0.1:8000/v1| V[vLLM]
  V --> G[NVIDIA GPU]
  H --> T[Tools: terminal, files, web]
```

**Distributed** (optional `start --lan`):

```mermaid
flowchart LR
  U[You] --> C[Controller Hermes]
  C -->|LAN :8000/v1| V[vLLM on GPU host]
  V --> G[NVIDIA GPU]
  C --> T[Tools on controller]
```

---

## Why "Enodios"?

**Enodios** (Ἐνόδιος) is a Greek epithet of Hermes — god of **roads, travelers, and crossroads**. This project is the local road between Hermes Agent and your GPU.

The name is unused in open source (0 PyPI/npm collisions when we picked it).

---

## Development

```bash
git clone https://github.com/DataKnifeAI/enodios.git
cd enodios
./bin/enodios install
```

---

## License

MIT — see [LICENSE](LICENSE).
