# ---------- BASE ----------
FROM pytorch/pytorch:2.8.0-cuda12.9-cudnn9-devel
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
RUN pip install -r requirements.txt

# ---------- INSTALL MODELSCOPE AND DOWNLOAD MODEL ----------
RUN pip install "modelscope"
RUN modelscope download --model IndexTeam/IndexTTS-2 --local_dir checkpoints

# ---------- COPY YOUR HANDLER ----------
COPY handler.py /workspace/index-tts/handler.py

# ---------- SETUP ENVIRONMENT ----------
ENV PYTHONPATH="/workspace/index-tts"

# ---------- LAUNCH HANDLER ----------
CMD ["python3","-u", "handler.py"]
