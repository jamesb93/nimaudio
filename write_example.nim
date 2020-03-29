import sndfile
import os
import strformat

var filesnd: ptr TSNDFILE
var info: TINFO

var sr = 44100
var channels = 1
var frames = 4 * sr

info.channels = cint(channels)
info.frames = int64(frames)
info.samplerate = cint(44100)
info.format = cint(int(SF_FORMAT_WAV) or int(SF_FORMAT_FLOAT))
info.seekable = cint(1)
info.sections = cint(1)

let filePath = paramStr(1).expandTilde()

filesnd = sndfile.open(
    filePath, 
    sndfile.WRITE,
    cast[ptr TINFO](info.addr)
    )

var samples = cast[ptr UncheckedArray[cfloat]](alloc0(sizeof(cfloat) * frames))

for i in 0..frames-1:
  samples[i] = cfloat(i)

let samples_C = cast[ptr cfloat](samples)

let items = channels * frames

var written_items = sndfile.writef_float(filesnd, samples_C, items)

echo "Created: " & filePath
echo fmt("Frames: {written_items}")

# Dealloc and close
discard sndfile.close(filesnd)
dealloc(samples)