# Command Decoder Testbench

This testbench verifies the functionality of the `cmd_decoder` block in isolation.

The decoder receives a complete command (`cmd`, `addr`, `data`) from the command collector and generates:
- Register file control signals
- One-cycle response pulses indicating success, data return, or error

## What is Tested

The following cases are covered:

1. **Valid WRITE command**
   - Generates a register write enable
   - Correct register address and write data
   - Produces an `OK` response pulse

2. **Valid READ command**
   - Returns register read data
   - Produces a `DATA` response pulse with address and data

3. **Invalid address**
   - Address outside the 16-register range (0x00–0x0F)
   - Produces an `ERR` response with error code

4. **Unknown command**
   - Unsupported command byte
   - Produces an `ERR` response with error code

## Testbench Notes

- The register file is **not instantiated** in this testbench.
- Register read data (`reg_rd_data`) is **mocked by the testbench** to verify decoder behavior in isolation.
- All response and control signals are expected to be **single-cycle pulses**.

## Waveform

The waveform below illustrates command execution and response signaling for the tested cases.

![cmd_decoder waveform](cmd_decoder_waveform.png)
