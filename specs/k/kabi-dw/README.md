# kabi-dw

The [kabi-dw](https://github.com/skozina/kabi-dw) package is a tool to detect any changes in the ABI between the successive builds of the Linux kernel. This is done by dumping the DWARF type information (the .debug_info section) for the specific symbols into the text files and later comparing the text files.
