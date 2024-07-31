# Local GLaDOS project

## Installation
This is made to work on WSL2.0 and can probably work on Windows with a similar setup
but is not confirmed.

Install `espeak-ng` and `ffmpeg`
```bash
# Arch
sudo pacman -S espeak-ng ffmpeg

# Ubuntu
sudo apt-get install espeak-ng ffmpeg
```

### Install and setup `python3.10` environment. 
It is important to not use a `conda` environment as it redirects library paths to a new relative path. This will break a required library dependency for `espeak` from the `deep_phonemizer` module later.

If Python3.10 is missing from `apt`, add the python version repo using the following commands
```bash
sudo apt install software-properties-common -y
sudo add-apt-repository ppa:deadsnakes/ppa
sudo apt update
```

Install python3.10
```bash
# Arch
sudo pacman -S python3.10 python3.10-venv

# Ubuntu
sudo apt install python3.10 python3.10-venv
```

With python install, create a virtual environment for GLaDOS with the following command
```bash
python3.10 -m venv path/to/env

# e.g. python3.10 -m venv ~/.env/GLaDOS
```

To activate the new environment, simply `source` the activate script in `path/to/env/bin/`. For less hassle, you can create an `alias` to run the sourcing. Add the following to your 
`.bashrc` (`.zshrc` if using `zsh` or similar for other shells).
```bash
alias gladosenv="source path/to/env/bin/activate"
```

With the environment activated, install the pip requirements. Install the required python packackes using the following command
```bash
pip install -r requirements.txt
```

When that finishes up, run `python` and make sure `cuda` is available using the following commands
```python
import torch
print(torch.cuda.is_available())
```

If it prints `False`, then try to reinstall PyTorch by following the official installation instructions [[here](https://pytorch.org/get-started/locally/)]

## Running the tool

To interact with the GLaDOS speech module, simply run the `GladosVoice.py` script and wait for it to load. 

```bash
python GladosVoice.py
```

You will be greeted by an input prompt where you can type text which is will interpret and play. The final audio file is exported to `output.wav`

**NOTE:** The first inference can use up to 1 second due to it loading the modules. Any subsequent inference will be significantly faster!

## Credits
- R2D2FISH - Glados TTS [[https://github.com/R2D2FISH/glados-tts](https://github.com/R2D2FISH/glados-tts)]
- JIK876 - HiFiGAN [[https://github.com/jik876/hifi-gan](https://github.com/jik876/hifi-gan)]
- Daswer123 - RVC-Python [[https://github.com/daswer123/rvc-python](https://github.com/daswer123/rvc-python)]
- QuickWick [[GLaDOS RVC model](https://huggingface.co/QuickWick/Music-AI-Voices/tree/main/GLaDOS%20(Portal%202)%20(RVC)%20V2%20300%20Epoch)]