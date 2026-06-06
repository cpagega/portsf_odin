// Copyright (c) 2009,2010 Richard Dobson

//Permission is hereby granted, free of charge, to any person
//obtaining a copy of this software and associated documentation
//files (the "Software"), to deal in the Software without
//restriction, including without limitation the rights to use,
//copy, modify, merge, publish, distribute, sublicense, and/or sell
//copies of the Software, and to permit persons to whom the
//Software is furnished to do so, subject to the following
//conditions:

//The above copyright notice and this permission notice shall be
//included in all copies or substantial portions of the Software.

//THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//OTHER DEALINGS IN THE SOFTWARE.


// PortSF Odin bindings
// Copyright (c) 2026 Christopher Page
//
// Based on PortSF by Richard Dobson.
// Original copyright (c) 2009,2010 Richard Dobson.

package portsf

import "core:c"

when ODIN_OS == .Windows{
    when ODIN_ARCH == .amd64{
        LIB_ARCH :: "x64"
    } else when ODIN_ARCH == .i386 {
        LIB_ARCH :: "x86"
    } else {
        #panic("Unsupported Windows architecture")
    }
} else {
    #panic("Unsupported OS")
}


@(private) LIB_PATH :: "lib/portsf_" + LIB_ARCH + ".lib"

when !#exists(LIB_PATH) {
    #panic("Could not find PortSF library at " + LIB_PATH)
}

foreign import lib {
    LIB_PATH,
}
    
// Supported file sample formats
psf_stype :: enum c.int {
    UNKNOWN = 0,
    SAMP_8, // this is not supported but its in the original spec..
    SAMP_16,
    SAMP_24,
    SAMP_32,
    IEEE_FLOAT,
}
// file format - based only on the read in file extension
psf_format :: enum c.int {
    UNKNOWN = 0,
    STDWAVE,
    WAVE_EX,
    AIFF,
    AIFC,
}

// error codes

E_NOERROR           ::  0
E_CANT_OPEN         :: -1
E_CANT_CLOSE        :: -2
E_CANT_WRITE        :: -3
E_CANT_READ         :: -4
E_NOT_WAVE          :: -5
E_BAD_TYPE          :: -6
E_BAD_FORMAT        :: -7
E_UNSUPPORTED       :: -8
E_NOMEM             :: -9
E_BADARG            :: -10
E_CANT_SEEK         :: -11
E_TOOMANYFILES      :: -12
E_FILE_READONLY     :: -13
E_SEEK_BEYOND_EOF   :: -14



// speaker consts
NUM_SPEAKER_POSITIONS :: 18

SPEAKER_FRONT_LEFT			  ::	0x1
SPEAKER_FRONT_RIGHT			  ::	0x2
SPEAKER_FRONT_CENTER		  ::	0x4
SPEAKER_LOW_FREQUENCY		  ::	0x8
SPEAKER_BACK_LEFT			  ::	0x10
SPEAKER_BACK_RIGHT			  ::	0x20
SPEAKER_FRONT_LEFT_OF_CENTER  ::	0x40
SPEAKER_FRONT_RIGHT_OF_CENTER ::	0x80
SPEAKER_BACK_CENTER			  ::	0x100
SPEAKER_SIDE_LEFT			  ::	0x200
SPEAKER_SIDE_RIGHT		      ::	0x400
SPEAKER_TOP_CENTER		      ::	0x800
SPEAKER_TOP_FRONT_LEFT		  ::	0x1000
SPEAKER_TOP_FRONT_CENTER	  ::	0x2000
SPEAKER_TOP_FRONT_RIGHT		  ::	0x4000
SPEAKER_TOP_BACK_LEFT		  ::	0x8000
SPEAKER_TOP_BACK_CENTER		  ::	0x10000
SPEAKER_TOP_BACK_RIGHT		  ::	0x20000
SPEAKER_RESERVED      		  ::	0x80000000

// my extras
SPKRS_UNASSIGNED	          ::    0
SPKRS_MONO			          ::    0x00000040
SPKRS_STEREO		          ::    0x00000003
SPKRS_GENERIC_QUAD	          ::    0x00000033
SPKRS_SURROUND_LCRS	          ::    0x00000107
SPKRS_SURR_5_0                ::    0x00000037
SPKRS_DOLBY5_1		          ::    0x0000003f
// NB more than one 7.1 layout in common use
SPKRS_7_1                     ::    0x0000007f
SPKRS_ACCEPT_ALL	          ::    0xffffffff	 //???? no use for a file

// support for the PEAK chunk
// in a WAVE or AIFF file pos is always 32 bits
PSF_CHPEAK :: struct {
    val:    c.float,
    pos:    c.ulong,
}

// likely only ever need RDWR
psf_create_mode :: enum c.int {
    CREATE_RDWR,
    CREATE_TEMPORARY,
    CREATE_WRONGLY,
}
// speakerfeed format 
psf_channelformat :: enum c.int {
    STDWAVE,
    MC_STD,
    MC_MONO,
    MC_STEREO,
    MC_QUAD,
    MC_LCRS,
    MC_BFMT,
    MC_DOLBY_5_1,
    MC_SURR_5_0,
    MC_SURR_7_1,
    MC_WAVE_EX,
}

// for psf_sndSeek() - maps to fseek flags
SEEK_SET :: 0
SEEK_CUR :: 1
SEEK_END :: 2

// dithering
DITHER_OFF  :: 0
DITHER_TPDF :: 1

// main struct used to define a soundfile. 

PSF_PROPS :: struct {
    srate:      c.int,
    chans:      c.int,
    samptype:   psf_stype,
    format:     psf_format,
    chformat:   psf_channelformat,
}

//*******************Public Functions********************

@(link_prefix="psf_", default_calling_convention="c")
foreign lib {
    // init sfs system. return 0 for success
    init            :: proc() -> c.int ---
    // close sfs system. return 0 for success
    finish          :: proc() -> c.int ---
    // find the soundfile format from the filename extension
    // supported: .wav, .aif, .aiff, .aifc, .afc, .amb
    GetFormatExt    :: proc(path: cstring) -> psf_format --- 
    // read speaker mask of WAVE_EX file
    speakermask     :: proc(sfd: c.int) -> c.int ---
    // find named speaker layout, or generic type such as MC_WAVE_EX
    speakerlayout   :: proc(chmask: c.ulong, chans: c.ulong) -> psf_channelformat ---

}

@(link_prefix="psf_snd", default_calling_convention="c")
foreign lib {
    //Create soundfile from props.
    //Supports clipping or non-clipping of floats to 0dbFS,
    //set minimum header (or use PEAK)
    //return Sf descriptor >= 0, or some E_ on error.

    // using WIN32, its possible to share for reading, but not under ANSI
    Create              :: proc(path: cstring, 
                                props: ^PSF_PROPS, 
                                clip_floats: c.int, 
                                minheader: c.int) -> c.int ---
    //open existing soundfile. receive format info in props. Supports auto rescale from PEAK
    //data, with floats files. Only RDONLY access supported.
    //Return sf descriptor >= 0, or some E_ on error.
    Open                :: proc(path: cstring,
                                props: ^PSF_PROPS,
                                rescale: c.int) -> c.int ---
    //close soundfile. Updates PEAK data if used. return 0 for success or E_ on error.
    Close               :: proc(sfd: c.int) -> c.int ---

    // all data read/write is counted in multi-channel(m/c) sample 'frames', NOT in raw samples.

    //get size of file, in m/c frames. Return size, or E_BADARG on bad sfd.
    Size                :: proc(sfd: c.int) -> c.int ---
    // write m/c frames of floats. this updates internal PEAK data automatically.
    // return num frames written, or some E_ on error.
    WriteFloatFrames    :: proc(sfd: c.int,
                                buf: [^]f32,
                                nFrames: c.ulong) -> c.int ---
    WriteDoubleFrames   :: proc(sfd: c.int,
                                buf: [^]f64,
                                nFrames: c.ulong) -> c.int ---
    WriteShortFrames    :: proc(sfd: c.int,
                                buf: [^]c.short,
                                nFrames: c.ulong) -> c.int ---
                                
    // get current m/c frame position in file, or E_ on error.
    Tell                :: proc(sfd: c.int) -> c.int ---
    // m/c frame wrapper for fseek. return 0 for success. Offset counted in m/c frames.
    // seekmode must but one of SEEK_ options 
    Seek                :: proc(sfd: c.int,
                                offset: c.int,
                                seekmode: c.int) -> c.int ---
    // read m/c sample frames into floats buffer. return nFrames, or some E_.
    // if file opened with rescale = 1, over-range floats data, as indicated by PEAK chunk,
    // is automatically scaled to 0dBFS.
    ReadFloatFrames     :: proc(sfd: c.int,
                                buf: [^]f32,
                                nFrames: c.ulong) -> c.int ---
    ReadDoubleFrames    :: proc(sfd: c.int,
                                buf: [^]f64,
                                nFrames: c.ulong) -> c.int ---
    // original author never got around to readShortFrames...

    // read peak data from file into PSF_CHPEAK struct. 
    // it's not documented in the original c header what the return value is but i'll assume 0 or some error.
    // note: peaktime isn't always valid, it's simple to calculate directly (peakdata.pos / sample rate).
    ReadPeaks           :: proc(sfd: c.int,
                                peakdata: []PSF_CHPEAK,
                                peaktime: ^c.long) -> c.int ---

    // set/unset dither.
    // returns 0 on success, -1 if error (unrecognized type, or read-only)
    // no-op for input files
    SetDither           :: proc(sfd: c.int,
                                dtype: c.uint) -> c.int ---
    GetDither           :: proc(sfd: c.int) -> c.int ---
    

}
