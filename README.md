# 📡 MATLAB Superheterodyne Receiver

A full MATLAB/GNU Octave implementation of a **superheterodyne receiver** with an FDM transmitter, built as a term project for **Communication System I (EC322M)** at the Arab Academy for Science, Technology and Maritime Transport (AASTMT).

---

## Table of Contents

- [Overview](#overview)
- [System Architecture](#system-architecture)
- [Repository Structure](#repository-structure)
- [Getting Started](#getting-started)
  - [Requirements](#requirements)
  - [Setup](#setup)
  - [Running the Transmitter](#running-the-transmitter)
  - [Running the Receiver](#running-the-receiver)
- [Receiver Stages](#receiver-stages)
- [Evaluating Performance Without the RF Stage](#evaluating-performance-without-the-rf-stage)
- [Effect of LO Frequency Offset](#effect-of-lo-frequency-offset)
- [System Parameters](#system-parameters)
- [Authors](#authors)

---

## Overview

This project implements a two-channel **Frequency Division Multiplexed (FDM)** communication system from transmitter to receiver:

- The **transmitter** reads two audio files, upsamples them to 1 MHz, DSB-SC modulates each onto a separate carrier (100 kHz and 150 kHz), and combines them into a single FDM composite signal.
- The **receiver** processes the FDM signal through a complete superheterodyne chain — RF filter → RF mixer → IF filter → coherent demodulator → LPF — and recovers each original audio signal independently.

The project also analyses the impact of **bypassing the RF stage** and the effect of **local oscillator frequency offsets** (0.1 kHz and 1 kHz) on audio quality.

---

## System Architecture

```
TRANSMITTER
──────────────────────────────────────────────────────────
  Conference.wav ──► Upsample (1 MHz) ──► × cos(2π·100k·t) ──┐
                                                               ├──► fdmSignal.wav
  Sports.wav     ──► Upsample (1 MHz) ──► × cos(2π·150k·t) ──┘


RECEIVER (superheterodyne chain)
──────────────────────────────────────────────────────────
                    ┌─ BPF (100 kHz) ─► × cos(2π·80k·t) ─► BPF (20 kHz) ─► × cos(2π·20k·t) ─► LPF ──► Signal 1
  fdmSignal.wav ───┤
                    └─ BPF (150 kHz) ─► × cos(2π·130k·t) ─► BPF (20 kHz) ─► × cos(2π·20k·t) ─► LPF ──► Signal 2
                      [RF Stage]         [RF Mixer]           [IF Stage]        [Coherent Det.]   [LPF]
```

---

## Repository Structure

```
SUPERHET-RECEIVER/
│
├── src/
│   ├── transmitter.m        # FDM transmitter — modulates & saves fdmSignal.wav
│   └── receiver.m           # Superheterodyne receiver — demodulates both channels
│
├── audio/
│   ├── .gitkeep             # Drop your .wav files here (see instructions inside)
│   ├── Conference.wav       # ← you provide this
│   └── Sports.wav           # ← you provide this
│
├── figures/
│   └── .gitkeep             # Output figures saved here (see instructions inside)
│
├── docs/
│   └── report.md            # Full stage-by-stage technical discussion
│
├── .gitignore
└── README.md
```

---

## Getting Started

### Requirements

- **MATLAB** R2018b or later, **or** [GNU Octave](https://octave.org/) 6.0+
- Signal Processing Toolbox (MATLAB) or the `signal` package (Octave)

Install the Octave signal package if needed:

```octave
pkg install -forge signal
pkg load signal
```

### Setup

1. Clone the repository:

```bash
git clone https://github.com/Sal03-git/SUPERHET-RECEIVER.git
cd SUPERHET-RECEIVER
```

2. Place your two input audio files in the `audio/` folder:

```
audio/Conference.wav
audio/Sports.wav
```

Any two `.wav` files (mono or stereo) will work. Stereo files are automatically averaged to mono.

### Running the Transmitter

```matlab
cd src
run('transmitter.m')
```

This generates `audio/fdmSignal.wav` and plots the time and frequency domain representations of each stage.

### Running the Receiver

```matlab
cd src
run('receiver.m')
```

This processes `audio/fdmSignal.wav` through the full receiver chain and:
- Saves `audio/demodulated_signal1.wav` and `audio/demodulated_signal2.wav`
- Plays both recovered signals through your speakers
- Displays figures for each stage (RF output, IF output, LPF output, etc.)

---

## Receiver Stages

| Stage | Component | Parameters |
|-------|-----------|------------|
| 1 | RF Bandpass Filter | 5th-order Butterworth, centred on Fc ±5 kHz |
| 2 | RF Mixer | Multiplies by cos(2π·(Fc−IF)·t), down-converts to IF |
| 3 | IF Bandpass Filter | 5th-order Butterworth, centred on 20 kHz ±5 kHz |
| 4 | Coherent Demodulator | Multiplies by cos(2π·IF·t), shifts to baseband |
| 5 | Low-Pass Filter | 5th-order Butterworth, 5 kHz cutoff |

For a full discussion of each stage see [`docs/report.md`](docs/report.md).

---

## Evaluating Performance Without the RF Stage

To test the receiver without the RF filter (and observe the degradation in SNR and audio quality), open `src/receiver.m` and change line:

```matlab
ENABLE_RF_STAGE = true;
```

to:

```matlab
ENABLE_RF_STAGE = false;
```

**Expected results:**

| Metric | With RF Stage | Without RF Stage |
|--------|--------------|-----------------|
| Audio quality | Loud and clear | Barely audible, heavily distorted |
| LPF output amplitude | Normal | 2–3 orders of magnitude lower |
| Cause | RF filter pre-selects the band | All noise + both FDM channels enter the mixer |

---

## Effect of LO Frequency Offset

A frequency offset in the local oscillator shifts the IF signal away from the IF filter's passband centre, degrading reception:

| LO Offset | Spectrum effect | Audio effect |
|-----------|----------------|--------------|
| 0.1 kHz | Minor IF misalignment, small spectral artefacts | Low-frequency hum (~100 Hz), still intelligible |
| 1 kHz | Significant spectral shift, partial IF filter attenuation | High-pitched whistle (~1 kHz), very difficult to understand |

To simulate an offset, change the local oscillator frequency in `receiver.m`:

```matlab
% Original (correct)
if_signal1 = rf_signal1 .* cos(2 * pi * (Fc1 - IF) * t);

% With 0.1 kHz offset
OFFSET = 100;  % Hz
if_signal1 = rf_signal1 .* cos(2 * pi * (Fc1 - IF + OFFSET) * t);
```

---

## System Parameters

| Parameter | Value |
|-----------|-------|
| Sampling rate | 1 MHz |
| Carrier 1 (Fc1) | 100 kHz |
| Carrier 2 (Fc2) | 150 kHz |
| Intermediate Frequency | 20 kHz |
| Channel bandwidth | ±5 kHz |
| Modulation | DSB-SC |
| Filter type | 5th-order Butterworth |
| Playback sample rate | 44.1 kHz |

---

## Authors

**Salaheldeen Abdelmoneim** — [github.com/Sal03-git](https://github.com/Sal03-git)  
**Galaleldeen Abdelmoneim**  
**Islam Mohamed Taher**

Arab Academy for Science, Technology and Maritime Transport — Electronics & Communications Engineering, 2024
