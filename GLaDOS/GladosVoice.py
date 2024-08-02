from glados_rvc import GladosRVC
from glados_tts import GladosTTS

from tools.text import prepare_text
from scipy.io.wavfile import write
import time
import tempfile
import subprocess
from pydub import AudioSegment
from pydub.playback import play
from nltk import download
from nltk.tokenize import sent_tokenize
from sys import modules as mod

glados_tts = GladosTTS(False, True)
glados_rvc = GladosRVC()

kwargs = {
    'stdout':subprocess.PIPE,
    'stderr':subprocess.PIPE,
    'stdin':subprocess.PIPE
}

def play(audio, name):
    audio.export(name, format = "wav")
    rvc_start_time = time.time()
    glados_rvc.run(name) 
    rvc_time = (time.time() - rvc_start_time)*1000
    print(f"RVC finishied in: {rvc_time:.3f}ms")

    if 'winsound' in mod:
            winsound.PlaySound(name, winsound.SND_FILENAME | winsound.SND_ASYNC)
    else:
        try:
            subprocess.Popen(["play", name], **kwargs)
        except FileNotFoundError:
            try:
                subprocess.Popen(["aplay", name], **kwargs)
            except FileNotFoundError:
                subprocess.Popen(["pw-play", name], **kwargs)
    

def speak(text, alpha: float=1.0, delay: float=0.1):
        download('punkt',quiet=True)
        sentences = sent_tokenize(text)
        audio = glados_tts.run_tts(sentences[0])
        pause = AudioSegment.silent(duration=delay)
        old_line = AudioSegment.silent(duration=1.0) + audio
        play(old_line, "old_line.wav")
        old_time = time.time()
        old_dur = old_line.duration_seconds
        new_dur = old_dur
        if len(sentences) > 1:
            for idx in range(1, len(sentences)):
                if idx % 2 == 1:
                    new_line = glados_tts.run_tts(sentences[idx])
                    audio = audio + pause + new_line
                    new_dur = new_line.duration_seconds
                else:
                    old_line = glados_tts.run_tts(sentences[idx])
                    audio = audio + pause + old_line
                    new_dur = old_line.duration_seconds
                time_left = old_dur - time.time() + old_time
                if time_left <= 0:
                    print("Processing is slower than realtime!")
                else:
                    time.sleep(time_left + delay)
                if idx % 2 == 1:
                    play(new_line, "new_line.wav")
                else:
                    play(old_line, "old_line.wav")
                old_time = time.time()
                old_dur = new_dur
        else:
            time.sleep(old_dur + 0.1)

        audio.export("output.wav", format = "wav")
        time_left = old_dur - time.time() + old_time
        if time_left >= 0:
            time.sleep(time_left + delay)
    
if __name__ == "__main__":
    while True:
        text = input("Input: ")
        if len(text) > 0:
            speak(text)