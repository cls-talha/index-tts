# ---------- BASE ----------
FROM pytorch/pytorch:2.8.0-cuda12.9-cudnn9-devel

# ---------- SYSTEM SETUP ----------
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    git git-lfs curl wget build-essential libssl-dev zlib1g-dev \
    libbz2-dev libreadline-dev libsqlite3-dev libncursesw5-dev \
    xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev \
    ffmpeg \
    && git lfs install \
    && rm -rf /var/lib/apt/lists/*

# ---------- INSTALL PYTHON 3.11 ----------
RUN wget https://www.python.org/ftp/python/3.11.6/Python-3.11.6.tgz && \
    tar -xf Python-3.11.6.tgz && \
    cd Python-3.11.6 && \
    ./configure --enable-optimizations && \
    make -j$(nproc) && \
    make altinstall && \
    cd .. && rm -rf Python-3.11.6*

# ---------- SET PYTHON 3.11 AS DEFAULT ----------
RUN update-alternatives --install /usr/bin/python3 python3 /usr/local/bin/python3.11 1 && \
    python3 --version && \
    curl -sS https://bootstrap.pypa.io/get-pip.py | python3.11

WORKDIR /workspace

# ---------- CLONE INDEX-TTS REPOSITORY ----------
RUN git clone https://github.com/index-tts/index-tts.git && cd index-tts && git lfs pull

WORKDIR /workspace/index-tts

# ---------- COPY REQUIREMENTS ----------
COPY requirements.txt /workspace/index-tts/requirements.txt

# ---------- INSTALL DEPENDENCIES ----------
RUN python3 -m pip install --upgrade pip && \
    python3 -m pip install -r requirements.txt

# ---------- INSTALL MODELSCOPE AND DOWNLOAD MODEL ----------
RUN python3 -m pip install "modelscope"
RUN modelscope download --model IndexTeam/IndexTTS-2 --local_dir checkpoints

# ---------- COPY YOUR HANDLER ----------
COPY handler.py /workspace/index-tts/handler.py

# ---------- SETUP ENVIRONMENT ----------
ENV PYTHONPATH="/workspace/index-tts"

# ---------- LAUNCH HANDLER ----------
CMD ["python3", "-u", "handler.py"]
