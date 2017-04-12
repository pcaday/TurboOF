# TurboOF

TurboOF is a portable implementation of the Forth language and Open Firmware, the former IEEE 1275 standard. If you're new to Open Firmware, it's a firmware standard which offers a unified interface for operating systems and device drivers across different hardward platforms and CPUs.

TurboOF is designed to be readily ported to new ISAs without requiring an external compiler or any runtime environment. A tiny assembly kernel (currently implemented for x86 and PowerPC) runs a very simple pre-Forth environment which in turn bootstraps a full Forth interpreter and simple native code compiler. On top of the Forth system is a full Open Firmware interface.

This repository comes with a command line application `tof` for x86 systems that runs under Mac OS X, Linux, and Windows hosts. It can be used as a plain Forth environment, or as a test bed for Open Firmware development. There are also Open Firmware device drivers for several PowerPC Macintosh systems (PowerBook 1400 and Beige G3, a.k.a. M2 and Gossamer), which are mostly of historical interest. 

## Note

This software is distributed as-is, with no warranty of any kind whatsoever. You may use this code solely for personal, non-commercial use, and all use is entirely at your own risk.
