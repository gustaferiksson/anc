# anc

Switch AirPods noise control from the terminal on macOS.

```sh
brew install gustaferiksson/tap/anc
```

```sh
anc                # noise cancellation <-> transparency
anc status         # print the current mode
anc on             # noise cancellation
anc off            # off (no noise control)
anc transparency
anc adaptive       # only on models that support it
anc toggle         # noise cancellation <-> transparency
anc --list         # modes this device supports, * marks the current one
```

Modes the connected device doesn't support are rejected.

## How it works

macOS exposes two undocumented Core Audio properties on the AirPods audio
device: `lstm` (the current listening mode: 1 off, 2 noise cancellation,
3 transparency, 4 adaptive) and `lsms` (a bitmask of supported modes). `anc`
writes `lstm` and the system audio stack sends the change to the AirPods. No
private frameworks, entitlement bypass or Accessibility permission.

Since the properties are undocumented, a macOS update can break this. Reading
the mode returns macOS's cached value, so it can disagree with the headphones
if a write was dropped.

Tested on macOS 27 with AirPods Max.
