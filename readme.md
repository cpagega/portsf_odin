# PortSF Odin Bindings

Odin bindings for the PortSF audio file library by Richard Dobson.

## Features

* Read and write WAV and AIFF files
* Float, double, and 16-bit sample support
* Multi-channel audio support
* Access to PEAK chunk metadata
* No external dependencies beyond the PortSF library

## Supported Platforms

Currently supported:

* Windows x86
* Windows x64

## Installation

Add the package to your Odin project and ensure the library files are present:

```text
portsf_odin/
├── portsf.odin
├── LICENSE
├── README.md
└── lib/
    ├── portsf_x86.lib
    └── portsf_x64.lib
```

## Usage

```odin
package main

import "core:fmt"
import psf "path/to/portsf_odin"

main :: proc() {
    if psf.init() != 0 {
        panic("Failed to initialize PortSF")
    }
    defer psf.finish()

    props: psf.PSF_PROPS

    sfd := psf.Open(
        "test.wav",
        &props,
        0,
    )

    if sfd < 0 {
        panic("Failed to open file")
    }
    defer psf.Close(sfd)

    fmt.println("Sample Rate:", props.srate)
    fmt.println("Channels:", props.chans)
    fmt.println("Sample Type:", props.samptype)
}
```

## Notes

PortSF counts audio data in multi-channel frames rather than raw samples.

For example:

* Mono: 1 frame = 1 sample
* Stereo: 1 frame = 2 samples
* 5.1: 1 frame = 6 samples

When reading or writing frame data, buffer sizes should account for the channel count.

I've replaced the inline asm found in psf_round with lrint().

I've not tested every function in this file. If you are the one other person in the world wanting to use this library with Odin please let me know if you find any issues.

I've been using this library with the The Audio Programming book. Old but pretty good. 

The examples and exercies in the book are in C and CPP, but I wanted to learn Odin so I made this binding following examples found in box2d to help me learn Odin in a way that is interesting to me.

The source is included if you would like to build the lib yourself.

## Building PortSF

These bindings expect prebuilt static libraries:

```text
lib/
├── portsf_x86.lib
└── portsf_x64.lib
```

The libraries included with this package were built using Microsoft Visual Studio.

If rebuilding PortSF yourself, ensure the static library is built using the static runtime (`/MT`) to avoid CRT linkage issues when linking from Odin.

## Original Project

PortSF was written by Richard Dobson.

Original copyright:

Copyright (c) 2009, 2010 Richard Dobson

PortSF is distributed under the MIT License.

## Binding Author

Christopher Page, 2026

