# Technical Report — MATLAB Superheterodyne Receiver

**Course:** Communication System I (EC322M)  
**Department:** Electronics & Communications Engineering  
**Institution:** Arab Academy for Science, Technology and Maritime Transport  
**Authors:** Salaheldeen Abdelmoneim, Galaleldeen Abdelmoneim, Islam Mohamed Taher

---

## 1. The Transmitter

### Tasks

1. Reading monophonic audio signals into MATLAB
2. Upsampling the audio signals
3. Modulating the audio signals (each on a separate carrier)
4. Addition of the modulated signals

### Discussion

**Reading Monophonic Audio Signals**

Audio files are imported using `audioread`. Both signals are averaged across stereo channels to produce a mono signal. This is the first step that allows the audio data to enter the MATLAB processing pipeline for further manipulation.

**Upsampling**

Upsampling increases the sampling rate of both audio signals to match the carrier frequencies used during modulation. Without this step, the modulated signals cannot be correctly combined — the low native sampling rate of the audio (typically 44.1 kHz) would not satisfy the Nyquist criterion for a 100 kHz or 150 kHz carrier. Both signals are resampled to a common target rate of **1 MHz** using MATLAB's `resample` function.

**DSB-SC Modulation**

Each audio signal is modulated onto a different carrier frequency using Double-Sideband Suppressed-Carrier (DSB-SC) modulation:

```
modulatedSignal1 = signal1_resampled .* cos(2π × Fc1 × t)   [Fc1 = 100 kHz]
modulatedSignal2 = signal2_resampled .* cos(2π × Fc2 × t)   [Fc2 = 150 kHz]
```

Placing each signal on a distinct carrier is the foundation of **Frequency Division Multiplexing (FDM)**, which allows multiple signals to share the same channel without interfering with each other, since they occupy non-overlapping frequency bands.

**FDM Signal**

The two modulated signals are summed to form the composite FDM signal:

```
fdmSignal = modulatedSignal1 + modulatedSignal2
```

This composite signal is saved as `audio/fdmSignal.wav` and used as the input to the receiver. The summation step is critical in communication systems where bandwidth efficiency is important — a single transmission channel carries multiple independent messages simultaneously.

---

## 2. The RF Stage

### Task

Apply a bandpass RF filter to select the desired carrier band, then mix the filtered signal down to the intermediate frequency (IF).

### Discussion

The RF (Radio Frequency) filter selects the desired frequency band and rejects all out-of-band signals and noise, ensuring only the targeted carrier components pass through to subsequent stages.

The mixer following the RF filter performs **frequency translation**: it multiplies the RF-filtered signal by a local oscillator set to `Fc - IF`, shifting the signal from its carrier frequency down to the intermediate frequency of 20 kHz. Operating at a fixed lower frequency (IF) rather than directly at the RF carrier simplifies amplification and filtering in later stages, since:

- Filter design is simpler at lower frequencies
- Lower frequencies require less power to amplify
- The IF stage can be designed once and reused regardless of which carrier is being received

**5th-order Butterworth bandpass filters** are used for the RF stage, centred on each carrier (100 kHz and 150 kHz) with ±5 kHz bandwidth.

---

## 3. The IF Stage

### Task

Apply a bandpass IF filter centred on the intermediate frequency (20 kHz).

### Discussion

The Intermediate Frequency (IF) filter stage is a critical component in the superheterodyne architecture. Its primary role is to selectively pass the down-mixed signals centred around 20 kHz while removing:

- Residual out-of-band signals not rejected by the RF filter
- Mixing products introduced by the RF mixer (image frequencies)
- Noise added along the signal path

Working at a fixed intermediate frequency provides **better selectivity and sensitivity** compared to directly processing the high-frequency RF signal. The IF stage's consistent operating frequency allows its filters to be optimised precisely for signal recovery, which significantly improves overall signal quality and SNR before demodulation.

A 5th-order Butterworth bandpass filter is used, centred on IF = 20 kHz with ±5 kHz bandwidth.

---

## 4. The Baseband Demodulator

### Task

Coherent detection to demodulate the signal from the IF stage back to baseband.

### Discussion

The coherent detector multiplies the IF-filtered signal by a locally generated carrier synchronised to the IF:

```
baseband = filtered_IF_signal .* cos(2π × IF × t)
```

This multiplication shifts the IF signal down to 0 Hz (baseband). Coherence — maintaining the correct phase relationship between the transmitted and local carriers — is critical. Phase errors introduce distortion and attenuate the recovered signal. In this implementation, the local oscillator is phase-locked by construction (same equation used at both ends).

The result is then passed through a 5th-order Butterworth **low-pass filter** with a 5 kHz cutoff to remove the double-frequency mixing product (at 2×IF = 40 kHz) and recover the clean baseband audio signal.

---

## 5. Performance Evaluation: Receiver Without the RF Stage

### With the RF Stage

The output audio is **loud and clear**. The RF stage provides two benefits:

1. **Amplification** — the signal arriving at the mixer is already at a usable level
2. **Filtering** — only the desired carrier band reaches the mixer; noise and the other FDM channel are rejected before mixing

As a result, the IF filter, demodulator, and LPF receive a clean, well-defined signal, producing high-quality audio output.

### Without the RF Stage

Without the RF filter, the **raw FDM composite signal** is fed directly into the RF mixer. This causes:

- **Poor SNR** — no pre-filtering means broadband noise and the unwanted FDM channel both enter the mixer
- **Image frequency problem** — the mixer translates not just the desired carrier band but also frequencies that land at the same IF from the wrong side (image frequencies)
- **Significant distortion** — the recovered audio is barely audible and heavily distorted

The output waveform amplitude at the LPF output is reduced by two to three orders of magnitude compared to the RF-enabled case (compare figures 6 and 10 in the original report).

**Conclusion:** The RF stage is indispensable. It acts as the front-end guard of the receiver, and removing it collapses signal quality entirely.

---

## 6. Effect of Local Oscillator Frequency Offset

When the receiver's local oscillator (LO) deviates from the ideal frequency, the IF signal is no longer centred correctly within the IF filter passband. Two offset levels were analysed:

### 0.1 kHz Offset

**Spectrum:** The IF signal shifts by 0.1 kHz from its intended centre. This minor misalignment causes slight spectral asymmetry and introduces small artefacts at the edge of the IF filter's passband.

**Sound quality:** A low-frequency hum (~0.1 kHz) is added to the demodulated audio. It is noticeable but relatively mild — the speech or music content remains largely intelligible.

### 1 kHz Offset

**Spectrum:** The IF signal shifts by 1 kHz, causing a significant portion of the signal spectrum to fall outside the IF filter passband. This attenuates the desired signal and allows more noise and interference through.

**Sound quality:** A high-pitched tone or whistle (~1 kHz) is superimposed on the audio. This is highly disruptive and makes the content difficult or impossible to understand. The degradation is far more severe than at 0.1 kHz.

**Key insight:** Even small LO frequency errors have audible consequences. This motivates the use of **Phase-Locked Loops (PLLs)** in practical receiver designs to keep the local oscillator phase- and frequency-synchronised to the received carrier.

---

## System Parameters Summary

| Parameter | Value |
|-----------|-------|
| Sampling rate (target) | 1 MHz |
| Carrier 1 (Fc1) | 100 kHz |
| Carrier 2 (Fc2) | 150 kHz |
| Intermediate Frequency (IF) | 20 kHz |
| Channel bandwidth (BW) | ±5 kHz |
| RF filter type | 5th-order Butterworth BPF |
| IF filter type | 5th-order Butterworth BPF |
| LPF type | 5th-order Butterworth LPF |
| Modulation scheme | DSB-SC |
| Playback sample rate | 44.1 kHz |
