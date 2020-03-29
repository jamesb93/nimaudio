#omni -b:64

proc get_omni_inputs() : cint {.importc, dynlib: "./libSine.so"}
proc get_omni_outputs() : cint {.importc, dynlib: "./libSine.so"}

proc Omni_UGenAllocInit64(ins_ptr : ptr ptr cdouble, bufsize : cint, samplerate : cdouble, buffer_interface : pointer) : pointer {.importc, dynlib: "./libSine.so"}
proc Omni_UGenPerform64(ugen_ptr : pointer, ins_ptr : ptr ptr cdouble, outs_ptr : ptr ptr cdouble, bufsize : cint) : void {.importc, dynlib: "./libSine.so"}
proc Omni_UGenFree(ugen_ptr : pointer) : void {.importc, dynlib: "./libSine.so"}

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

for i in 0..(num_ins-1):
    dealloc(ins_nim[i])

for i in 0..(num_outs-1):
    dealloc(outs_nim[i])

dealloc(ins)
dealloc(outs)