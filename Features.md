# Features

## Bluetooth FTMS Explorer

Scans for Bluetooth Low Energy peripherals, connects to one, and walks its entire
GATT database — every service, characteristic, and descriptor. Readable
characteristics are read, subscribable ones are subscribed to, and every value is
decoded and appended to an on-disk session log in real time. Built to turn an
undocumented fitness machine into something inspectable.

## Fitness Machine Service decoding

Specification-aware decoders for the standard FTMS characteristics: Stair Climber,
Step Climber, Cross Trainer, Treadmill, Rower, and Indoor Bike data, plus the
feature bit fields, training status, and supported-range characteristics. Anything
without a dedicated decoder falls through to a raw inspector that renders the
payload as text, bytes, and words in both endiannesses.

## LiXuan WLT5283M vendor layout

Handles the non-conforming Stair Climber Data layout used by the LiXuan `WLT5283M`
controller in STEPR machines, which declares 25 bytes' worth of flags and sends 23.
Verified byte-for-byte against the machine's own console. Also derives a live step
rate, which the firmware does not transmit.

## PitPat treadmill vendor protocol

Decodes the proprietary protocol used by PitPat-app treadmills and walking pads,
such as the SupeRun `BA10-B`. These machines do not implement FTMS at all: they
advertise as `PitPat-T01` and carry telemetry on service `FBA0`, characteristic
`FBA2`, in a big-endian 31-byte frame. Reports speed, target and maximum speed,
distance, steps, calories, elapsed time, belt state, and firmware version, and
surfaces the bytes whose meaning is still unknown.

## FitShow treadmill vendor protocol

Decodes the framed protocol used by FitShow-app treadmills, such as the maksone
`SL-Z01` (Ningbo Kangruida `AMA005726`). Telemetry arrives on service `FFF0`,
`FFE0`, or `AE00` in a little-endian packet wrapped in a header, footer, and XOR
checksum. Because those service UUIDs are generic and widely reused, the decoder
treats the verifying checksum as the proof that a device really is a FitShow
machine, and falls back to a hex dump for anything else. Handles the status,
info, session-data, control, and console-key frame families. The protocol carries
no unit marker, so unlabelled speed and distance values are shown under both
metric and imperial readings.

## Session logging

Every connection writes a timestamped log file named after the device, capturing
the advertisement, the full discovery sweep, and every value received, with a
running tail mirrored on screen.
