import sndfile
import os

var 
    Filename = "~/validfile.wav".expandTilde()
    Info: TINFO
    File = sndfile.open(Filename, sndfile.READ, Info.addr)

if File == nil:
  echo("quitter...")
  quit(-1)

echo("Channels: " & $Info.channels)
echo("Frames: " & $Info.frames)
echo("Samplerate: " & $Info.samplerate)
echo("Format: " & $Info.format)
echo("Seekable?: " & $Info.seekable)
echo("Sections: " & $Info.sections)