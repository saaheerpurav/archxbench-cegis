That is not an output-scaling arithmetic mismatch. This module:

- Has no clock
- Has no reset
- Has no `done`
- Has no array outputs
- Has no file I/O
- Only transforms one signed scalar sample combinationally

So it cannot be responsible for creating `dut_output.json`.

### Current implementation behavior