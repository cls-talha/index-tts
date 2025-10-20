from indextts.infer_v2 import IndexTTS2
import torch
import gc

def clear_torch_memory():
    gc.collect()
    torch.cuda.empty_cache()
    torch.cuda.ipc_collect()


clear_torch_memory()
tts = IndexTTS2(cfg_path="checkpoints/config.yaml", model_dir="checkpoints", use_fp16=False, use_cuda_kernel=False, use_deepspeed=False)
text = """““In a world driven by innovation and speed, one idea can change everything. This… is where it begins”"""
# [happy, angry, sad, afraid, disgusted, melancholic, surprised, calm]
tts.infer(spk_audio_prompt='examples/Clint_Eastwood CC3 (enhanced2).wav', text=text, output_path="outputs/gen111.mp3", emo_vector=[0, 0, 0, 0, 0, 0, 0.45, 0], use_random=True, verbose=True)
clear_torch_memory()
