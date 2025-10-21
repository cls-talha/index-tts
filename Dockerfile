FROM pytorch/pytorch:2.8.0-cuda12.9-cudnn9-devel

ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies for building Python 3.11
RUN apt-get update && apt-get install -y --no-install-recommends \
    software-properties-common \
    wget \
    build-essential \
    libssl-dev \
    zlib1g-dev \
    libncurses5-dev \
    libncursesw5-dev \
    libreadline-dev \
    libsqlite3-dev \
    libffi-dev \
    libbz2-dev \
    && rm -rf /var/lib/apt/lists/*

# Download and install Python 3.11
RUN wget https://www.python.org/ftp/python/3.11.5/Python-3.11.5.tgz \
    && tar xzf Python-3.11.5.tgz \
    && cd Python-3.11.5 \
    && ./configure --enable-optimizations \
    && make -j$(nproc) \
    && make altinstall \
    && cd .. \
    && rm -rf Python-3.11.5 Python-3.11.5.tgz

# Set python3 and pip3 to point to Python 3.11
RUN update-alternatives --install /usr/bin/python3 python3 /usr/local/bin/python3.11 1 \
    && update-alternatives --install /usr/bin/pip3 pip3 /usr/local/bin/pip3.11 1

# Now your Dockerfile can continue as usual

RUN apt-get update && apt-get install -y --no-install-recommends \
    git git-lfs curl ffmpeg \
    && git lfs install \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace

RUN git clone https://github.com/index-tts/index-tts.git && cd index-tts && git lfs pull

WORKDIR /workspace/index-tts

COPY requirements.txt /workspace/index-tts/requirements.txt

RUN pip3 install -r requirements.txt

RUN pip3 install "modelscope"
RUN modelscope download --model IndexTeam/IndexTTS-2 --local_dir checkpoints

COPY handler.py /workspace/index-tts/handler.py

ENV PYTHONPATH="/workspace/index-tts"

CMD ["python3", "handler.py"]
