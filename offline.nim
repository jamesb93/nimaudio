#omni -b:64

import sndfile
import os
import strformat

proc get_omni_inputs() : cint {.importc, dynlib: "./libChaos.dll"}
proc get_omni_outputs() : cint {.importc, dynlib: "./libChaos.dll"}

proc Omni_UGenAllocInit64(ins_ptr : ptr ptr cdouble, bufsize : cint, samplerate : cdouble, buffer_interface : pointer) : pointer {.importc, dynlib: "./libSine.so"}
proc Omni_UGenPerform64(ugen_ptr : pointer, ins_ptr : ptr ptr cdouble, outs_ptr : ptr ptr cdouble, bufsize : cint) : void {.importc, dynlib: "./libSine.so"}
proc Omni_UGenFree(ugen_ptr : pointer) : void {.importc, dynlib: "./libChaos.dll"}

type
    CDoublePtr*    = ptr UncheckedArray[cdouble]      #double*
    CDoublePtrPtr* = ptr UncheckedArray[CDoublePtr]   #double**

#Init
let 
    samplerate = 48000.0
    bufsize = 48000

    num_ins  = int(get_omni_inputs())
    num_outs = int(get_omni_outputs())

    ins  = cast[ptr ptr cdouble](alloc0(sizeof(ptr cdouble) * num_ins))
    ins_nim = cast[CDoublePtrPtr](ins)
    
    outs = cast[ptr ptr cdouble](alloc0(sizeof(ptr cdouble) * num_outs))
    outs_nim = cast[CDoublePtrPtr](outs)

#Ins
for i in 0..(num_ins-1):
    let ins_vec = cast[CDoublePtr](alloc0(sizeof(cdouble) * bufsize))
    
    for y in 0..(bufsize-1):
        ins_vec[y] = 440.0
    
    ins_nim[i] = ins_vec

#Outs
for i in 0..(num_outs-1):
    let outs_vec = cast[CDoublePtr](alloc0(sizeof(cdouble) * bufsize))
    
    for y in 0..(bufsize-1):
        outs_vec[y] = 1.0
    
    outs_nim[i] = outs_vec

#Allocate and init omni object
let omni_ugen = Omni_UGenAllocInit64(cast[ptr ptr cdouble](nil), cint(bufsize), cdouble(samplerate), cast[pointer](nil))

#Perform DSP
Omni_UGenPerform64(omni_ugen, ins, outs, cint(bufsize))

#Free memory
Omni_UGenFree(omni_ugen)

################
# File writing #
################
var filesnd: ptr TSNDFILE
var info: TINFO

var sr = cint(samplerate)
var channels = 1
var frames = sr

info.channels = cint(channels)
info.frames = int64(frames)
info.samplerate = cint(sr)
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

for i in 0..(frames-1):
  samples[i] = cfloat(i)

let samples_C = cast[ptr cfloat](samples)

let items = channels * frames

var written_items = sndfile.writef_float(filesnd, samples_C, items)

echo fmt("Created: {filePath}")
echo fmt("Frames: {written_items}")


################
# Deallocation #
################
discard sndfile.close(filesnd)
dealloc(samples)

for i in 0..(num_ins-1):
    dealloc(ins_nim[i])

for i in 0..(num_outs-1):
    dealloc(outs_nim[i])

dealloc(ins)
dealloc(outs)