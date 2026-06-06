# UART on AMD Urbana FPGA

This project implements a UART system in SystemVerilog on the AMD Urbana FPGA board. The design was built incrementally: first a baud-rate generator, then independent TX and RX modules, then TX-to-RX loopback simulation, FPGA loopback, and finally a PC -> FPGA -> PC echo test.

The goal is to understand the full UART data path from timing generation through real serial communication with a PC terminal.

## Project Setup

The project was created in Vivado for the AMD Urbana FPGA board. The board clock is 100 MHz, constrained with:

```tcl
set_property PACKAGE_PIN N15 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]
create_clock -period 10.000 [get_ports clk]
```

The UART design uses standard 8N1 framing:

- 1 start bit
- 8 data bits
- No parity bit
- 1 stop bit

## Baud Generator

UART modules need a timing pulse at the selected baud rate. With a 100 MHz FPGA clock, the baud interval is:

```text
BAUD_CYCLES = 100,000,000 / BAUD
```

The baud generator counts system clock cycles and asserts `baud_tick` for one clock cycle whenever the selected baud interval expires.

```systemverilog
module baud_generator #(
    parameter BAUD = 9600
) (
    input  logic rst,
    input  logic clk,
    output logic baud_tick
);
```

Common baud rates considered:

| Baud Rate | Typical Use |
| --- | --- |
| 300-2400 | Low-speed or legacy systems |
| 9600 | Common default for simple embedded projects |
| 19200 | Industrial automation |
| 38400 | Logging and control systems |
| 115200 | Common PC serial terminal speed |
| 230400+ | Higher-throughput serial links |

### Baud Generator Verification

The baud generator is verified by checking that:

- The counter resets correctly.
- `baud_tick` occurs after the expected number of clock cycles.
- `baud_tick` is exactly one clock cycle wide.
- `baud_tick` does not occur early.

9600 Baud:
<img width="2767" height="419" alt="image" src="https://github.com/user-attachments/assets/d7d9eb95-c200-40c8-b1b7-05bb58d1e6ba" />

115200 Baud:
<img width="2767" height="419" alt="image" src="https://github.com/user-attachments/assets/429cb76d-4a2b-43a0-bf79-328a21fdc49e" />

## UART Transmitter

The transmitter waits in `IDLE` with the serial line high. When `tx_start` is asserted, it latches `tx_data`, sends a low start bit, sends 8 data bits LSB-first, then sends a high stop bit before returning to idle.

FSM:

```text
IDLE -> START -> DATA -> STOP -> IDLE
```

```systemverilog
module tx (
    input  logic clk,
    input  logic rst,
    input  logic baud_tick,
    input  logic tx_start,
    input  logic [7:0] tx_data,
    output logic tx_busy,
    output logic tx_serial
);
```

For a byte such as `8'h55`, the expected serial frame is:

```text
start, bit0, bit1, bit2, bit3, bit4, bit5, bit6, bit7, stop
0,     1,    0,    1,    0,    1,    0,    1,    0,    1
```

### TX Verification

The TX testbench builds the expected UART frame as:

```systemverilog
expected_frame = {1'b1, data, 1'b0};
```

This looks reversed, but it allows the checker to index from bit 0 upward:

```text
expected_frame[0] = start bit
expected_frame[1] = data bit 0
...
expected_frame[9] = stop bit
```

The checker samples `tx_serial` on each `baud_tick` and raises a fatal error if any bit does not match.

9600 Baud:
<img width="1927" height="410" alt="image" src="https://github.com/user-attachments/assets/a03a1c38-7c59-4053-908a-54321e420b1f" />

115200 Baud:
<img width="2767" height="419" alt="image" src="https://github.com/user-attachments/assets/a9da02a2-4231-4196-9db7-7bcdc572dcc7" />


## UART Receiver

The receiver is slightly more complex than the transmitter because RX does not control the timing. It watches `rx_serial`, detects the start bit, waits until the middle of the bit period, and then samples each data bit once per baud interval.

FSM:

```text
IDLE -> START -> DATA -> STOP -> IDLE
```

RX behavior:

- `IDLE`: Wait for `rx_serial` to go low.
- `START`: Wait half a baud period and confirm the line is still low.
- `DATA`: Sample 8 data bits LSB-first, one baud period apart.
- `STOP`: Finish the frame, update `rx_data`, and pulse `rx_done`.

```systemverilog
module rx #(
    parameter BAUD = 9600
) (
    input  logic rst,
    input  logic clk,
    input  logic rx_serial,
    output logic rx_busy,
    output logic rx_done,
    output logic [7:0] rx_data
);
```

### RX Verification

The RX testbench manually drives `rx_serial` with full UART frames:

```text
start bit 0 -> 8 data bits LSB-first -> stop bit 1
```

The serial stimulus and checker run in parallel using `fork...join`. The checker waits for RX activity, then compares `rx_data` against the expected byte.

9600 Baud:
<img width="1918" height="306" alt="image" src="https://github.com/user-attachments/assets/fff1a542-0782-4642-b6e6-64ef4c675b17" />

115200 Baud:
<img width="1671" height="299" alt="image" src="https://github.com/user-attachments/assets/315c6aea-0a57-4f1b-9ed2-b94c205d653d" />


## TX -> RX Loopback Simulation

After TX and RX were verified independently, they were connected together in simulation:

```text
tx_serial -> rx_serial
```

The loopback testbench starts the transmitter, waits for the receiver to finish, and checks that the received byte matches the transmitted byte. This proves that the UART modules work together as a complete serial path.

<img width="2919" height="372" alt="image" src="https://github.com/user-attachments/assets/d08b92bf-9c6b-4c25-9f5a-2ed006548f7f" />

## FPGA Internal Loopback

The FPGA loopback test connects TX directly to RX inside the top module. A hardcoded byte, such as `8'h55`, is transmitted when a button is pressed. The received byte is compared against the expected value and displayed on the RGB LED.

Test flow:

1. Press reset.
2. Press the start button.
3. TX sends `8'h55`.
4. RX receives the serial frame.
5. Green LED indicates a correct byte.
6. Red LED indicates a mismatch.

In this linked video, I give a brief overview of the simple test. 

https://github.com/user-attachments/assets/9f2cf9f2-dc07-4362-9436-cfde25eea37d



## PC -> FPGA -> PC Echo

The final test is a real UART echo path:

```text
PC terminal -> FPGA RX -> FPGA TX -> PC terminal
```

The PC sends a character over the Urbana board UART connection. The FPGA receives the byte, then transmits the same byte back. If local echo is disabled in the serial terminal, the typed character should only appear when the FPGA sends it back.

Echo control:

```systemverilog
if (rx_done && !tx_busy) begin
    tx_data <= rx_data;
    tx_start <= 1'b1;
end
```

Serial terminal settings:

```text
Baud rate: match RTL parameter, for example 115200
Data bits: 8
Parity: none
Stop bits: 1
Flow control: none
```

This first video demonstrates me opening a serial terminal in Vitis with a matching baud rate to my UART implementation: 115200.

https://github.com/user-attachments/assets/33840908-715d-4f75-b9f7-c7500b18b5d6

This second video shows what happens when we set our serial terminal to a mismatch baud rate.

https://github.com/user-attachments/assets/635d0608-13e6-44b2-b708-9b2c0b2ec6d7



## Notes and Lessons Learned

- UART TX is easier because it controls when the serial line changes.
- UART RX needs careful sampling because it only observes the serial line.
- RX should sample near the middle of each bit period.
- `rx_done` is useful because it clearly marks when a new byte is available.
- Self-checking testbenches are more useful than waveform-only debugging.
- Hardware buttons should eventually be synchronized and debounced before driving one-cycle control pulses.

