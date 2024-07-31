from rvc_python.modules.vc.modules import VC
from rvc_python.configs.config import Config
from rvc_python.download_model import download_rvc_models

from scipy.io import wavfile

import os
import torch

class GladosRVC:
    def __init__(self):
        self.model_path = "models/rvc"
        self.glados_model = f"{self.model_path}/glados2333333.pth"
        self.glados_index = f"{self.model_path}/IVF2170_Flat_nprobe_1.index"

        self.device = 'cuda' if torch.cuda.is_available() else 'cpu'
        print("Using device: " + self.device)

        download_rvc_models(self.model_path)
        config = Config(self.model_path, "cuda")
        self.vc = VC(self.model_path, config)
        self.vc.get_vc(self.glados_model, "v2")

    def run(self, target="temp/output.wav"):
        if not os.path.isfile(target):
            print("Error: target file not found.") 
            return

        wav_opt = self.vc.vc_single(
            sid=1,
            input_audio_path=target,
            f0_up_key=0,
            f0_method="rmvpe",
            file_index=self.glados_index,
            index_rate=1.0,
            filter_radius=3,
            resample_sr=0.0,
            rms_mix_rate=0.5,
            protect=0.33,
            f0_file="",
            file_index2=""
        )
        wavfile.write("output.wav", self.vc.tgt_sr, wav_opt)