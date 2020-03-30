#omni -b:64

import sndfile
import os
import strformat

proc get_omni_inputs() : cint {.importc, dynlib: "./libLorenz.dylib"}
proc get_omni_outputs() : cint {.importc, dynlib: "./libLorenz.dylib"}

proc Omni_UGenAllocInit64(ins_ptr : ptr ptr cdouble, bufsize : cint, samplerate : cdouble, buffer_interface : pointer) : pointer {.importc, dynlib: "./libLorenz.dylib"}
proc Omni_UGenPerform64(ugen_ptr : pointer, ins_ptr : ptr ptr cdouble, outs_ptr : ptr ptr cdouble, bufsize : cint) : void {.importc, dynlib: "./libLorenz.dylib"}
proc Omni_UGenFree(ugen_ptr : pointer) : void {.importc, dynlib: "./libLorenz.dylib"}

#################
# Input Reading #
#################
var 
    inPath = "./ir.wav"
    inInfo: TINFO
    inFile: ptr TSNDFILE

inFile = sndfile.open(inPath, sndfile.READ, inInfo.addr)

let
    inFrames = inInfo.frames
    inSr = inInfo.samplerate

    inItems = cast[cint](inInfo.channels * inInfo.frames)
    inBuffer = cast[ptr UncheckedArray[cdouble]](alloc0(sizeof(cdouble) * inFrames))

var inItemCount = sndfile.readf_double(inFile, inBuffer[0].addr, inItems)
echo "initem count below"
echo inItemCount
echo "initem"

    


# echo("Channels: " & $inInfo.channels)
# echo("Frames: " & $iInfo.frames)
# echo("Samplerate: " & $inInfo.samplerate)
# echo("Format: " & $inInfo.format)
# echo("Seekable?: " & $inInfo.seekable)
# echo("Sections: " & $inInfo.sections)
# let num_items = cast[cint](info.channels * info.frames)
# echo num_items
# var buffer = newSeq[cint](num_items)
# let items_read = read_int(snd_file, buffer[0].addr, num_items
############
# OMNI DSP #
############

type
    CDoublePtr*    = ptr UncheckedArray[cdouble]      #double*
    CDoublePtrPtr* = ptr UncheckedArray[CDoublePtr]   #double**

#Init
let 
    samplerate = cint(inSr)
    bufsize = cint(inFrames)

    num_ins  = int(get_omni_inputs())
    
    num_outs = int(get_omni_outputs())
    

    ins  = cast[ptr ptr cdouble](alloc0(sizeof(ptr cdouble) * num_ins))
    ins_nim = cast[CDoublePtrPtr](ins)
    
    outs = cast[ptr ptr cdouble](alloc0(sizeof(ptr cdouble) * num_outs))
    outs_nim = cast[CDoublePtrPtr](outs)
#Ins

ins_nim[0] = inBuffer
for i in 1..(num_ins-1):
    let ins_vec = cast[CDoublePtr](alloc0(sizeof(cdouble) * bufsize))
    var param_value: float
    # if i == 0: param_value = 1.0
    if i == 1: param_value = 10.0
    if i == 2: param_value = 28.0
    if i == 3: param_value = 2.67
    if i == 4: param_value = 0.01
    for y in 0..(bufsize-1): ins_vec[y] = param_value
    
    ins_nim[i] = ins_vec

#Outs
for i in 0..(num_outs-1):
    let outs_vec = cast[CDoublePtr](alloc0(sizeof(cdouble) * bufsize))
    for y in 0..(bufsize-1): outs_vec[y] = 0.0
    
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
var frames = bufsize

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

# var samples = cast[ptr UncheckedArray[cfloat]](alloc0(sizeof(cfloat) * frames))

# for i in 0..(frames-1):
#   samples[i] = cfloat(i)

# let samples_C = cast[ptr cfloat](samples)
let bufPtr = cast[ptr cdouble](outs_nim[0])

let items = channels * frames

var written_items = sndfile.writef_double(
    filesnd, 
    bufPtr, 
    bufsize)

echo fmt("Created: {filePath}")
echo fmt("Frames: {written_items}")


###############
#Deallocation #
###############
discard sndfile.close(filesnd)
for i in 0..(num_ins-1):
    dealloc(ins_nim[i])

for i in 0..(num_outs-1):
    dealloc(outs_nim[i])

dealloc(ins)
dealloc(outs)