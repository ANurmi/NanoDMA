# NanoDMA

A simple, low-latency DMA. Compatible to a generic TCDM/OBI (subset) protocol on the read & write interfaces, config through a generic REG/APB-style interface.

## Integration
This IP is developed as a part of [Atalanta](https://github.com/soc-hub-fi/atalanta). Testing is (for now) limited exclusively to software-based integration level tests inside the microcontroller project.

## Memory Map

| Register (32-bit) | Base Address Offset |
|-------------------|---------------------|
| CfgAddr           | 0x0                 |
| ReadAddr          | 0x4                 |
| WriteAddr         | 0x8                 |

### `CfgAddr` Layout

| 31      | 30-8   | 7-0            |
|---------|--------|----------------|
| StartTX | unused | TxLen (Max 255)|