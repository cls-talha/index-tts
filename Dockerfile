# ---------- BASE IMAGE ---------- 
FROM pytorch/pytorch:2.8.0-cuda12.9-cudnn9-devel

# ---------- SYSTEM SETUP ----------
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    git git-lfs curl wget build-essential libssl-dev zlib1g-dev \
    libbz2-dev libreadline-dev libsqlite3-dev libncursesw5-dev \
    xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev \
    ffmpeg && \
    git lfs install && \
    rm -rf /var/lib/apt/lists/*

# ---------- INSTALL PYTHON 3.11 ----------
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3.11 python3.11-venv python3.11-dev python3-pip && \
    ln -sf /usr/bin/python3.11 /usr/local/bin/python3 && \
    ln -sf /usr/bin/python3.11 /usr/local/bin/python && \
    python3 --version && \
    curl -sS https://bootstrap.pypa.io/get-pip.py | python3.11 && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /workspace

# ---------- CLONE INDEX-TTS REPOSITORY ----------
RUN git clone https://github.com/index-tts/index-tts.git && \
    cd index-tts && \
    git lfs pull

WORKDIR /workspace/index-tts

# ---------- COPY REQUIREMENTS ----------
COPY requirements.txt /workspace/index-tts/requirements.txt

# ---------- INSTALL DEPENDENCIES ----------
RUN python3.11 -m pip install --upgrade pip && \
    python3.11 -m pip install -r requirements.txt

# ---------- INSTALL MODELSCOPE AND DOWNLOAD MODEL ----------
RUN python3.11 -m pip install "modelscope" && \
    modelscope download --model IndexTeam/IndexTTS-2 --local_dir checkpoints

# ---------- COPY YOUR HANDLER ----------
COPY handler.py /workspace/index-tts/handler.py

# ---------- SETUP ENVIRONMENT ----------
ENV PYTHONPATH="/workspace/index-tts"

# ---------- LAUNCH HANDLER ----------
CMD ["python3.11", "-u", "handler.py"]
