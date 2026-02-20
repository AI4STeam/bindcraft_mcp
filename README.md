# BindCraft MCP

**Model Context Protocol (MCP) server for protein binder design using BindCraft**

Design high-affinity protein binders against target proteins using:
- **AF2 Hallucination** — Generate binder backbone conformations
- **MPNN Sequence Design** — Optimize amino acid sequences
- **AF2 Validation** — Predict and validate complex structures
- **PyRosetta Scoring** — Evaluate interface quality and energy

## Quick Start

### Approach 1: Automated Setup (Recommended)

The fastest way to get started:

```bash
cd bindcraft_mcp
bash quick_setup.sh
```

This creates the conda environment, clones BindCraft, installs all dependencies, and displays the Claude Code configuration.

**Requirements:**
- Conda or Mamba (mamba recommended)
- Python 3.10+
- NVIDIA GPU with CUDA (recommended for design tasks)

### Approach 2: Manual Setup

For custom installations, see [details.md](details.md#installation-details).

---

## MCP Server Installation

After running the setup script, register the server with Claude Code:

```bash
# Option 1: Using fastmcp (Recommended)
fastmcp install src/bindcraft_mcp.py --name bindcraft

# Option 2: Manual installation
claude mcp add bindcraft -- $(pwd)/env/bin/python $(pwd)/src/bindcraft_mcp.py

# Verify installation
claude mcp list
```

---

## Verify Installation

You should now see the BindCraft MCP server listed:

```bash
claude mcp list
```

In Claude Code, you can use these 5 tools:
- `bindcraft_design_binder` — Quick synchronous binder design
- `bindcraft_submit` — Submit async design jobs
- `bindcraft_check_status` — Monitor job progress
- `generate_config` — Auto-generate configurations from PDB
- `validate_config` — Validate configuration files

---

## Next Steps

- **Detailed documentation**: See [details.md](details.md) for comprehensive guides on:
  - Local Python script usage (5 use cases)
  - All available MCP tools and parameters
  - Example workflows and tutorials
  - Configuration options
  - Troubleshooting

- **Quick Start in Claude Code**: Try these example prompts:

```
Generate a binder for @examples/data/PDL1.pdb with 3 designs targeting chain A
```

```
Generate configuration for @examples/data/PDL1.pdb with detailed analysis
```

```
Submit an async binder design job for @examples/data/PDL1.pdb with 5 designs
```

---

## Directory Structure

```
./
├── README.md               # Quick start (this file)
├── details.md              # Comprehensive documentation
├── env/                    # Conda environment
├── src/
│   ├── bindcraft_mcp.py    # MCP server (main entry point)
│   └── tools/              # Tool implementations
├── clean_scripts/          # 5 standalone use-case scripts
├── examples/data/          # Demo data (PDL1.pdb)
├── configs/                # Configuration templates
└── repo/                   # BindCraft repository
```

---

## Key Features

✅ **Synchronous Design** — Fast results for single targets (1-10 minutes)
✅ **Async Processing** — Long-running jobs for complex designs (>10 minutes)
✅ **Batch Processing** — Process multiple targets concurrently
✅ **Job Management** — Complete lifecycle tracking and monitoring
✅ **Auto Config** — Generate optimized parameters from PDB files
✅ **GPU Acceleration** — Full CUDA and JAX/XLA support
✅ **Error Handling** — Robust error reporting and recovery

---

## Local Script Usage

You can also run the tools directly without MCP:

```bash
# create environment
bash quick_setup.sh
mamba activate ./env

# Quick design
python clean_scripts/use_case_1_quick_design.py \
  --input examples/data/PDL1.pdb \
  --output results/

# Async job submission
python clean_scripts/use_case_2_async_submission.py \
  --input examples/data/PDL1.pdb --num-designs 3

# Monitor progress
python clean_scripts/use_case_3_monitor_progress.py --output results/

# Batch processing
python clean_scripts/use_case_4_batch_design.py --input examples/data/

# Config generation
python clean_scripts/use_case_5_config_generator.py \
  --input examples/data/PDL1.pdb --validate
```

See [details.md](details.md#local-usage-scripts) for full parameter documentation.

---

## Troubleshooting

**Environment not found?**
```bash
bash quick_setup.sh
```

**GPU not available?**
```bash
nvidia-smi  # Check NVIDIA drivers
python -c "import jax; print(jax.devices())"  # Check JAX
```

**MCP server not registered?**
```bash
claude mcp list
claude mcp remove bindcraft
fastmcp install src/bindcraft_mcp.py --name bindcraft
```

See [details.md](details.md#troubleshooting) for more troubleshooting guidance.

---

## License

Based on the original [BindCraft](https://github.com/martinpacesa/BindCraft) repository by Martin Pacesa and colleagues.
