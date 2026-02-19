###############################################################################
# BindCraft MCP – Docker Image
#
# Multi-stage build:
#   1. builder  – installs all conda/pip dependencies
#   2. runtime  – minimal image with only what's needed to run
#
# Build:
#   docker build -t bindcraft-mcp .
#
# Run (GPU):
#   docker run --gpus all -it bindcraft-mcp
#
# Run (CPU-only):
#   docker run -it bindcraft-mcp
###############################################################################

# ---------- Stage 1: builder ----------
FROM continuumio/miniconda3:24.7.1-0 AS builder

RUN apt-get update && apt-get install -y \
    git gcc g++ wget \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Create conda environment with all dependencies
RUN conda create -p /env python=3.10 -y

# Install core conda packages
RUN conda install -p /env \
    pip pandas matplotlib 'numpy<2.0.0' biopython scipy seaborn \
    libgfortran5 tqdm ffmpeg fsspec \
    -c conda-forge -y

# Install ML packages
RUN conda install -p /env \
    chex dm-haiku 'flax<0.10.0' dm-tree joblib ml-collections immutabledict optax \
    -c conda-forge -y

# Install JAX with CUDA 12 support for GPU acceleration
RUN /env/bin/pip install --no-cache-dir 'jax[cuda12]>=0.4,<=0.6.0'

# Install PyRosetta (may fail without license – non-fatal)
RUN conda install -p /env pyrosetta pdbfixer \
    --channel https://conda.graylab.jhu.edu -c conda-forge -y 2>/dev/null || true

# Install pip packages
RUN /env/bin/pip install --no-cache-dir fastmcp==2.13.1 loguru click
RUN /env/bin/pip install --no-cache-dir git+https://github.com/sokrypton/ColabDesign.git --no-deps || true

# Clean conda cache
RUN conda clean -a -y

# ---------- Stage 2: runtime ----------
FROM continuumio/miniconda3:24.7.1-0 AS runtime

RUN apt-get update && apt-get install -y \
    libgomp1 git wget \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy conda environment from builder
COPY --from=builder /env /env

# Copy source code
COPY src/ ./src/
COPY clean_scripts/ ./clean_scripts/
COPY configs/ ./configs/

# Create directories for runtime
RUN mkdir -p tmp/inputs tmp/outputs jobs results repo/scripts/params repo/scripts/functions

# Clone BindCraft repository and set up scripts
RUN git clone --depth 1 https://github.com/martinpacesa/BindCraft repo/BindCraft \
    && cp repo/BindCraft/bindcraft.py repo/scripts/run_bindcraft.py \
    && cp -r repo/BindCraft/functions/* repo/scripts/functions/ 2>/dev/null || true \
    && chmod +x repo/scripts/functions/dssp repo/scripts/functions/DAlphaBall.gcc 2>/dev/null || true

# Download AlphaFold2 weights into the image (~5.3 GB)
RUN wget -q https://storage.googleapis.com/alphafold/alphafold_params_2022-12-06.tar \
        -O /app/repo/scripts/params/alphafold_params.tar \
    && tar -xf /app/repo/scripts/params/alphafold_params.tar -C /app/repo/scripts/params/ \
    && rm -f /app/repo/scripts/params/alphafold_params.tar

# Symlink so MCP tools can find scripts at /app/scripts
RUN ln -s /app/repo/scripts /app/scripts

# Copy examples (needed for default filter/advanced settings)
COPY examples/ ./examples/

ENV PYTHONPATH=/app/src:/app/clean_scripts
ENV PATH=/env/bin:$PATH
# Enable GPU access for NVIDIA Container Toolkit
ENV NVIDIA_VISIBLE_DEVICES=all
ENV NVIDIA_DRIVER_CAPABILITIES=compute,utility

CMD ["python", "src/bindcraft_mcp.py"]
