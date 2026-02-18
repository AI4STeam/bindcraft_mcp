# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

BindCraft MCP is a FastMCP server for protein binder design. It wraps the [BindCraft](https://github.com/martinpacesa/BindCraft) pipeline (AF2 hallucination → MPNN sequence design → AF2 validation → PyRosetta scoring) into 5 MCP tools for use by AI agents.

## Common Commands

```bash
# Setup environment
bash quick_setup.sh

# Run the MCP server
./env/bin/python src/bindcraft_mcp.py

# Development mode with auto-reload
fastmcp dev src/bindcraft_mcp.py

# Run tests (from project root)
./env/bin/python tests/test_tools.py

# Docker build and run
docker build -t bindcraft-mcp .
docker run --gpus all -it bindcraft-mcp
```

## Architecture

**Entry point:** `src/bindcraft_mcp.py` — creates a `FastMCP(name="bindcraft")` server and mounts two sub-MCPs.

**Tool modules** (each exports its own FastMCP instance that gets mounted):
- `src/tools/bindcraft_design.py` → `bindcraft_design_mcp` — 3 tools: `bindcraft_design_binder` (sync), `bindcraft_submit` (async), `bindcraft_check_status`
- `src/tools/bindcraft_config.py` → `bindcraft_config_mcp` — 2 tools: `generate_config`, `validate_config`

**Job management:** `src/jobs/manager.py` — handles background subprocess execution with threading for stdout/stderr collection, tracks job lifecycle (PENDING → RUNNING → COMPLETED/FAILED).

**Standalone scripts:** `clean_scripts/` contains 5 use-case scripts (`use_case_1` through `use_case_5`) with shared library in `clean_scripts/lib/`. These run independently of MCP. The config tools import from `clean_scripts/lib/` by inserting it into `sys.path`.

**BindCraft repo:** Cloned into `repo/BindCraft/` during setup; key files copied to `repo/scripts/`. The design tools locate BindCraft via relative path from `src/tools/` → `../../scripts/`.

## Key Patterns

- **Tool definition:** Use `@mcp.tool` decorator with `Annotated[type, "description"]` for all parameters. Always return `dict`.
- **Path handling:** All user-provided paths are resolved to absolute via `_resolve_path()` before use.
- **Subprocess execution:** Design tools run BindCraft as a subprocess with `CUDA_VISIBLE_DEVICES` and `XLA_FLAGS` env vars. Stdout/stderr are collected via threads to avoid deadlocks.
- **Error returns:** Tools never raise exceptions to the caller; they return `{"status": "error", "error_message": ...}` dicts.
- **Logging:** All modules use `loguru.logger`.

## Environment

- Python 3.10, conda-based environment at `./env/`
- GPU: CUDA 12.x required for design tasks; config tools are CPU-only
- Heavy conda dependencies (JAX, PyRosetta, dm-haiku, flax) — not pip-installable
- AlphaFold2 weights (~5.3 GB) stored at `repo/scripts/params/`

## CI/CD

- `.github/workflows/docker.yml` — builds and pushes Docker image to GHCR on push to main or version tags
