import runpod
import os
import uuid
import subprocess
import torch
import gc
import shutil
import requests
from indextts.infer_v2 import IndexTTS2


# -----------------------------
# Utilities
# -----------------------------
def clear_torch_memory():
    gc.collect()
    if torch.cuda.is_available():
        torch.cuda.empty_cache()
        torch.cuda.ipc_collect()


def ensure_folder(path):
    if not os.path.exists(path):
        os.makedirs(path, exist_ok=True)


def download_if_url(path_or_url, save_dir="inputs"):
    """Download file if it's a URL; otherwise return local path."""
    ensure_folder(save_dir)
    if path_or_url.startswith("http://") or path_or_url.startswith("https://"):
        filename = os.path.basename(path_or_url).split("?")[0] or f"{uuid.uuid4()}"
        tmp_path = os.path.join(save_dir, filename)
        r = requests.get(path_or_url, stream=True)
        with open(tmp_path, "wb") as f:
            shutil.copyfileobj(r.raw, f)
        return tmp_path
    return path_or_url


# -----------------------------
# Load model once globally
# -----------------------------
print("Loading TTS model...")
tts = None
try:
    tts = IndexTTS2(
        cfg_path="checkpoints/config.yaml",
        model_dir="checkpoints",
        use_fp16=True,
        use_cuda_kernel=False,
        use_deepspeed=False
    )
    print("TTS model loaded successfully.")
except Exception as e:
    print(f"Model load failed: {e}")
    tts = None


# -----------------------------
# Handler
# -----------------------------
def handler(event):
    input_data = event.get("input", {})
    task = input_data.get("task")

    if not task:
        return {"status": "error", "message": "Missing 'task' in input."}

    if tts is None:
        return {"status": "error", "message": "Model failed to load."}

    uid = str(uuid.uuid4())
    output_dir = "outputs"
    ensure_folder(output_dir)

    try:
        # ---------------------- TTS CLONE ----------------------
        if task == "tts_clone":
            text = input_data["text"]
            spk_audio_path = download_if_url(input_data["spk_audio_prompt"])
            out_path = os.path.join(output_dir, f"tts_clone_{uid}.mp3")

            clear_torch_memory()
            tts.infer(spk_audio_prompt=spk_audio_path, text=text, output_path=out_path)
            clear_torch_memory()

            return {"status": "success", "task": task, "output_path": out_path, "uuid": uid}

        # ---------------------- TTS EMOTION AUDIO ----------------------
        elif task == "tts_emotion_audio":
            text = input_data["text"]
            emo_alpha = float(input_data.get("emo_alpha", 1.0))
            spk_audio_path = download_if_url(input_data["spk_audio_prompt"])
            emo_audio_path = download_if_url(input_data["emo_audio_prompt"])
            out_path = os.path.join(output_dir, f"tts_emo_audio_{uid}.mp3")

            clear_torch_memory()
            tts.infer(
                spk_audio_prompt=spk_audio_path,
                emo_audio_prompt=emo_audio_path,
                emo_alpha=emo_alpha,
                text=text,
                output_path=out_path
            )
            clear_torch_memory()

            return {"status": "success", "task": task, "output_path": out_path, "uuid": uid}

        # ---------------------- TTS EMOTION VECTOR ----------------------
        elif task == "tts_emotion_vector":
            text = input_data["text"]
            emo_vector = [float(x) for x in input_data["emo_vector"].split(",")]
            spk_audio_path = download_if_url(input_data["spk_audio_prompt"])
            out_path = os.path.join(output_dir, f"tts_emo_vec_{uid}.mp3")

            clear_torch_memory()
            tts.infer(
                spk_audio_prompt=spk_audio_path,
                text=text,
                emo_vector=emo_vector,
                output_path=out_path
            )
            clear_torch_memory()

            return {"status": "success", "task": task, "output_path": out_path, "uuid": uid}

        # ---------------------- MERGE VIDEO + AUDIO ----------------------
        elif task == "merge":
            video_path = download_if_url(input_data["video"])
            audio_path = download_if_url(input_data["audio"])
            out_path = os.path.join(output_dir, f"merged_{uid}.mp4")

            cmd = [
                "ffmpeg", "-y",
                "-i", video_path,
                "-i", audio_path,
                "-map", "0:v:0",
                "-map", "1:a:0",
                "-c:v", "copy",
                "-c:a", "aac",
                "-b:a", "192k",
                "-async", "1",
                out_path
            ]
            subprocess.run(cmd, check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

            return {"status": "success", "task": task, "output_path": out_path, "uuid": uid}

        else:
            return {"status": "error", "message": f"Unknown task: {task}"}

    except Exception as e:
        return {"status": "error", "message": str(e)}

    finally:
        clear_torch_memory()


# -----------------------------
# RunPod Entrypoint
# -----------------------------
runpod.serverless.start({"handler": handler})
