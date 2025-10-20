# ---------- BASE ----------
FROM nvidia/cuda:12.1.0-cudnn8-runtime-ubuntu22.04

# ---------- SYSTEM SETUP ----------
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
    git git-lfs curl python3 python3-venv python3-pip ffmpeg \
    && git lfs install \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace

# ---------- CLONE INDEX-TTS REPOSITORY ----------
RUN git clone https://github.com/index-tts/index-tts.git && cd index-tts && git lfs pull

WORKDIR /workspace/index-tts

# ---------- COPY REQUIREMENTS ----------
COPY requirements.txt /workspace/index-tts/requirements.txt

# ---------- INSTALL DEPENDENCIES ----------
RUN pip install --upgrade pip setuptools wheel \
    && pip install -r requirements.txt

# ---------- INSTALL MODELSCOPE AND DOWNLOAD MODEL ----------
RUN pip install "modelscope"
RUN modelscope download --model IndexTeam/IndexTTS-2 --local_dir checkpoints

# ---------- COPY YOUR HANDLER ----------
COPY handler.py /workspace/index-tts/handler.py

# ---------- SETUP ENVIRONMENT ----------
ENV PYTHONPATH="/workspace/index-tts"

# ---------- LAUNCH HANDLER ----------
CMD ["python3", "handler.py"]
