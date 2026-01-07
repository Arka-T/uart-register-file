# Command Decoder (UART Register File)

This block implements the command decoding logic for the UART-controlled
register file system.

The decoder processes complete commands collected by the `cmd_collector`
module and determines the required system action.

## Functionality

Each command consists of three bytes:
- Command (CMD)
- Address (ADDR)
- Data (DATA)

The decoder reacts to a one-cycle `cmd_ready` pulse and performs exactly
one action per command.

## Supported Commands

- `0x57` ('W') – WRITE  
  Writes `DATA` to the register at `ADDR` if the address is valid.

- `0x52` ('R') – READ  
  Reads data from the register at `ADDR` if the address is valid.

## Addressing Rules

- Valid register addresses: `0x00` – `0x0F`
- Addresses outside this range result in an error response.

## Responses

The decoder generates one-cycle response signals used by the UART TX logic:

- `resp_ok`   – Write successful (`'K'`)
- `resp_data` – Read response with data (`'D'`)
- `resp_err`  – Error response (`'E'`)

Error codes:
- `0x01` – Unknown command
- `0x02` – Invalid address

## Status

RTL implementation and testbench are work in progress.
