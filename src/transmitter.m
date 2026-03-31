% ============================================================
%  SUPERHETERODYNE RECEIVER — TRANSMITTER
%  Course: Communication System I (EC322M)
%  Arab Academy for Science, Technology and Maritime Transport
% ============================================================
%  Implements an FDM transmitter:
%    1. Reads two mono audio signals
%    2. Upsamples both to 1 MHz
%    3. DSB-SC modulates each onto a separate carrier
%       Signal 1 → Fc1 = 100 kHz
%       Signal 2 → Fc2 = 150 kHz
%    4. Sums the two modulated signals (FDM)
%    5. Saves the composite FDM signal to audio/fdmSignal.wav
% ============================================================

% Ensure the signal package is available (GNU Octave)
if isempty(ver('signal'))
    pkg install -forge signal
end
pkg load signal

% ── Audio input ──────────────────────────────────────────────
AUDIO_DIR = fullfile(fileparts(mfilename('fullpath')), '..', 'audio');

[signal1, Fs1] = audioread(fullfile(AUDIO_DIR, 'Conference.wav'));
[signal2, Fs2] = audioread(fullfile(AUDIO_DIR, 'Sports.wav'));

% Convert stereo to mono by averaging channels
signal1 = mean(signal1, 2);
signal2 = mean(signal2, 2);

% ── Upsample to 1 MHz ────────────────────────────────────────
targetFs = 1000000;

signal1_resampled = resample(signal1, targetFs, Fs1);
signal2_resampled = resample(signal2, targetFs, Fs2);

% Zero-pad the shorter signal so both are the same length
maxLength = max(length(signal1_resampled), length(signal2_resampled));
signal1_resampled = [signal1_resampled; zeros(maxLength - length(signal1_resampled), 1)];
signal2_resampled = [signal2_resampled; zeros(maxLength - length(signal2_resampled), 1)];

% ── DSB-SC modulation ────────────────────────────────────────
Fc1 = 100000;  % Carrier 1: 100 kHz
Fc2 = 150000;  % Carrier 2: 150 kHz

t = (0:maxLength-1)' / targetFs;  % Time vector

modulatedSignal1 = signal1_resampled .* cos(2 * pi * Fc1 * t);
modulatedSignal2 = signal2_resampled .* cos(2 * pi * Fc2 * t);

% ── FDM: sum the two modulated signals ───────────────────────
fdmSignal = modulatedSignal1 + modulatedSignal2;

% ── Save output ──────────────────────────────────────────────
audiowrite(fullfile(AUDIO_DIR, 'fdmSignal.wav'), fdmSignal, targetFs);
disp('FDM signal saved to audio/fdmSignal.wav');

% ── Plots: Time domain ───────────────────────────────────────
figure('Name', 'Transmitter — Time & Frequency Domain');

subplot(5, 2, 1);
plot(t, signal1_resampled);
title('Signal 1 (Time Domain)');
xlabel('Time (s)'); ylabel('Amplitude');

subplot(5, 2, 3);
plot(t, modulatedSignal1);
title('Modulated Signal 1 — 100 kHz (Time Domain)');
xlabel('Time (s)'); ylabel('Amplitude');

subplot(5, 2, 5);
plot(t, signal2_resampled);
title('Signal 2 (Time Domain)');
xlabel('Time (s)'); ylabel('Amplitude');

subplot(5, 2, 7);
plot(t, modulatedSignal2);
title('Modulated Signal 2 — 150 kHz (Time Domain)');
xlabel('Time (s)'); ylabel('Amplitude');

subplot(5, 2, 9);
plot(t, fdmSignal);
title('FDM Signal (Time Domain)');
xlabel('Time (s)'); ylabel('Amplitude');

% ── Plots: Frequency domain ──────────────────────────────────
N = length(fdmSignal);
f = (-N/2 : N/2-1) * (targetFs / N);

fftSignal1          = fftshift(fft(signal1_resampled));
fftModulatedSignal1 = fftshift(fft(modulatedSignal1));
fftSignal2          = fftshift(fft(signal2_resampled));
fftModulatedSignal2 = fftshift(fft(modulatedSignal2));
fftFdmSignal        = fftshift(fft(fdmSignal));

subplot(5, 2, 2);
plot(f, abs(fftSignal1) / N);
title('Signal 1 (Frequency Domain)');
xlabel('Frequency (Hz)'); ylabel('Magnitude');

subplot(5, 2, 4);
plot(f, abs(fftModulatedSignal1) / N);
title('Modulated Signal 1 (Frequency Domain)');
xlabel('Frequency (Hz)'); ylabel('Magnitude');

subplot(5, 2, 6);
plot(f, abs(fftSignal2) / N);
title('Signal 2 (Frequency Domain)');
xlabel('Frequency (Hz)'); ylabel('Magnitude');

subplot(5, 2, 8);
plot(f, abs(fftModulatedSignal2) / N);
title('Modulated Signal 2 (Frequency Domain)');
xlabel('Frequency (Hz)'); ylabel('Magnitude');

subplot(5, 2, 10);
plot(f, abs(fftFdmSignal) / N);
title('FDM Signal (Frequency Domain)');
xlabel('Frequency (Hz)'); ylabel('Magnitude');
