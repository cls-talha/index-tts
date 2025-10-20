import requests, os, tempfile, shutil

BASE_URL = "http://127.0.0.1:8000"
VOICE_PATH = "examples/voice_preview_aria.mp3"
EMO_PATH = "examples/emo_sad.wav"
VIDEO_PATH = "output11.mp4"

TEMP_DIR = tempfile.mkdtemp(prefix="indextts_test_")
print(f"Running tests in temp folder: {TEMP_DIR}\n")

def pretty(r):
    try:
        return r.json()
    except Exception:
        return {"error": r.text}

def test(endpoint, files, data=None):
    url = f"{BASE_URL}{endpoint}"
    r = requests.post(url, files=files, data=data)
    print(f"{endpoint}: {r.status_code}")
    print(pretty(r), "\n")
    return r

if __name__ == "__main__":
    try:
        # with open(VOICE_PATH, "rb") as f:
        #     test("/tts/clone", {"spk_audio_prompt": f}, {"text": "Every step, every move this is my rhythm, my fire. The world fades, and only the beat remains."})

        # with open(VOICE_PATH, "rb") as spk, open(EMO_PATH, "rb") as emo:
        #     test("/tts/emotion_audio", {"spk_audio_prompt": spk, "emo_audio_prompt": emo},
        #          {"text": "The city fell silent under crimson sky.", "emo_alpha": "0.8"})

        # with open(VOICE_PATH, "rb") as f:
        #     test("/tts/emotion_vector", {"spk_audio_prompt": f},
        #          {"text": "He’s coming! Quick, hide!.",
        #           "emo_vector": "0,0,0,0,0,0,0.45,0", "use_random": "True"})

        # with open(VOICE_PATH, "rb") as f:
        #     test("/tts/emotion_text_auto", {"spk_audio_prompt": f},
        #          {"text": "He’s coming! Quick, hide!", "emo_alpha": "0.6", "use_random": "True"})

        # with open(VOICE_PATH, "rb") as f:
        #     test("/tts/emotion_text_custom", {"spk_audio_prompt": f},
        #          {"text": "He’s coming! hide!", "emo_text": "panic tone", "emo_alpha": "0.6", "use_random": "True"})

        # pass here generated audio whatever you wanna add in back of video
        if os.path.exists(VIDEO_PATH): 
            with open(VIDEO_PATH, "rb") as v, open("outputs/tts_clone_89880da7-eecb-4163-a025-08625345866c.mp3", "rb") as a:
                test("/merge", {"video": v, "audio": a})
        else:
            print("Skipping merge — no video found.\n")

    finally:
        shutil.rmtree(TEMP_DIR, ignore_errors=True)
        print("Temporary files deleted.")
