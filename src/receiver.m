% ============================================================
%  SUPERHETERODYNE RECEIVER
%  Course: Communication System I (EC322M)
%  Arab Academy for Science, Technology and Maritime Transport
% ============================================================
%  Implements a full superheterodyne receiver chain:
%    1. RF bandpass filter  — selects the desired carrier band
%    2. RF mixer            — down-converts to IF (20 kHz)
%    3. IF bandpass filter  — removes out-of-band noise
%    4. IF mixer            — coherent demodulator (×cos(IF·t))
%    5. LPF                 — extracts the baseband audio
%
%  Set ENABLE_RF_STAGE = false to evaluate performance without
%  the RF filter and observe the degradation in audio quality.
% ============================================================

pkg load signal

% ── Configuration ────────────────────────────────────────────
ENABLE_RF_STAGE = true;   % Set false to bypass the RF filter

AUDIO_DIR = fullfile(fileparts(mfilename('fullpath')), '..', 'audio');

% ── Load FDM signal ──────────────────────────────────────────
[fdmSignal, Fs] = audioread(fullfile(AUDIO_DIR, 'fdmSignal.wav'));
disp(['Sampling Frequency: ', num2str(Fs), ' Hz']);

targetFs = 1000000;
if Fs ~= targetFs
    error('Loaded Fs (%d) does not match expected targetFs (%d).', Fs, targetFs);
end

% ── System parameters ─────────────────────────────────────────
Fc1 = 100000;   % Carrier 1: 100 kHz
Fc2 = 150000;   % Carrier 2: 150 kHz
IF  =  20000;   % Intermediate frequency: 20 kHz
BW  =   5000;   % Channel bandwidth: ±5 kHz

t = (0:length(fdmSignal)-1)' / Fs;

% ── Validate cutoff frquencies ────────────────────────────────
fc1_low  = (Fc1 - BW) / (Fs/2);
fc1_high = (Fc1 + BW) / (Fs/2);
fc2_low  = (Fc2 - BW) / (Fs/2);
fc2_high = (Fc2 + BW) / (Fs/2);
if_low   = (IF  - BW) / (Fs/2);
if_high  = (IF  + BW) / (Fs/2);
lp_cutoff = BW  / (Fs/2);

freqs = [fc1_low, fc1_high, fc2_low, fc2_high, if_low, if_high, lp_cutoff];
if any(freqs <= 0 | freqs >= 1)
    error('One or more normalised cutoff frequencies fall outside (0, 1). Check Fs and BW.');
end

% ── 5th-order Butterworth filters ────────────────────────────
[b_rf1, a_rf1] = butter(5, [fc1_low, fc1_high], 'bandpass');
[b_rf2, a_rf2] = butter(5, [fc2_low, fc2_high], 'bandpass');
[b_if,  a_if ] = butter(5, [if_low,  if_high ], 'bandpass');
[b_lp,  a_lp ] = butter(5,  lp_cutoff,          'low');

% ═══════════════════════════════════════════════════════════════
%  STAGE 1 — RF Filter
% ═══════════════════════════════════════════════════════════════
if ENABLE_RF_STAGE
    rf_signal1 = filter(b_rf1, a_rf1, fdmSignal);
    rf_signal2 = filter(b_rf2, a_rf2, fdmSignal);
    disp('RF stage: ENABLED');
else
    % Bypass — feed raw FDM directly into the mixer
    rf_signal1 = fdmSignal;
    rf_signal2 = fdmSignal;
    disp('RF stage: DISABLED (evaluating degraded performance)');
end

% ── Plot RF output ────────────────────────────────────────────
figure('Name', 'RF Stage Output');
subplot(2,1,1);
plot(t, rf_signal1);
title('RF Filtered Signal 1 (100 kHz)');
xlabel('Time (s)'); ylabel('Amplitude');
subplot(2,1,2);
plot(t, rf_signal2);
title('RF Filtered Signal 2 (150 kHz)');
xlabel('Time (s)'); ylabel('Amplitude');

% ═══════════════════════════════════════════════════════════════
%  STAGE 2 — RF Mixer: down-convert to IF (20 kHz)
% ═══════════════════════════════════════════════════════════════
if_signal1 = rf_signal1 .* cos(2 * pi * (Fc1 - IF) * t);
if_signal2 = rf_signal2 .* cos(2 * pi * (Fc2 - IF) * t);

figure('Name', 'RF Mixer Output (before IF filter)');
subplot(2,1,1);
plot(t, if_signal1);
title('IF Signal 1 — Down-mixed to 20 kHz');
xlabel('Time (s)'); ylabel('Amplitude');
subplot(2,1,2);
plot(t, if_signal2);
title('IF Signal 2 — Down-mixed to 20 kHz');
xlabel('Time (s)'); ylabel('Amplitude');

% ═══════════════════════════════════════════════════════════════
%  STAGE 3 — IF Bandpass Filter
% ═══════════════════════════════════════════════════════════════
filtered_if_signal1 = filter(b_if, a_if, if_signal1);
filtered_if_signal2 = filter(b_if, a_if, if_signal2);

% Save IF signals
audiowrite(fullfile(AUDIO_DIR, 'if_signal1.wav'), filtered_if_signal1, Fs);
audiowrite(fullfile(AUDIO_DIR, 'if_signal2.wav'), filtered_if_signal2, Fs);

figure('Name', 'IF Filter Output');
subplot(2,1,1);
plot(t, filtered_if_signal1);
title('Filtered IF Signal 1');
xlabel('Time (s)'); ylabel('Amplitude');
subplot(2,1,2);
plot(t, filtered_if_signal2);
title('Filtered IF Signal 2');
xlabel('Time (s)'); ylabel('Amplitude');

% ═══════════════════════════════════════════════════════════════
%  STAGE 4 — Coherent Demodulator: multiply by cos(IF·t)
% ═══════════════════════════════════════════════════════════════
baseband_signal1 = filtered_if_signal1 .* cos(2 * pi * IF * t);
baseband_signal2 = filtered_if_signal2 .* cos(2 * pi * IF * t);

figure('Name', 'Coherent Demodulator Output (before LPF)');
subplot(2,1,1);
plot(t, baseband_signal1);
title('Baseband Signal 1 (Before LPF)');
xlabel('Time (s)'); ylabel('Amplitude');
subplot(2,1,2);
plot(t, baseband_signal2);
title('Baseband Signal 2 (Before LPF)');
xlabel('Time (s)'); ylabel('Amplitude');

% ═══════════════════════════════════════════════════════════════
%  STAGE 5 — Low-Pass Filter
% ═══════════════════════════════════════════════════════════════
demodulated_signal1 = filter(b_lp, a_lp, baseband_signal1);
demodulated_signal2 = filter(b_lp, a_lp, baseband_signal2);

% Normalise
demodulated_signal1 = demodulated_signal1 / max(abs(demodulated_signal1));
demodulated_signal2 = demodulated_signal2 / max(abs(demodulated_signal2));

figure('Name', 'LPF Output — Recovered Baseband');
subplot(2,1,1);
plot(t, demodulated_signal1);
title('Baseband Signal 1 (After LPF)');
xlabel('Time (s)'); ylabel('Amplitude');
subplot(2,1,2);
plot(t, demodulated_signal2);
title('Baseband Signal 2 (After LPF)');
xlabel('Time (s)'); ylabel('Amplitude');

% ── Resample for playback and save ───────────────────────────
playbackFs = 44100;
demod1_playback = resample(demodulated_signal1, playbackFs, Fs);
demod2_playback = resample(demodulated_signal2, playbackFs, Fs);

audiowrite(fullfile(AUDIO_DIR, 'demodulated_signal1.wav'), demod1_playback, playbackFs);
audiowrite(fullfile(AUDIO_DIR, 'demodulated_signal2.wav'), demod2_playback, playbackFs);
disp('Demodulated signals saved to audio/');

% ── Playback ─────────────────────────────────────────────────
sound(demod1_playback, playbackFs);
pause(length(demod1_playback) / playbackFs);
sound(demod2_playback, playbackFs);
pause(length(demod2_playback) / playbackFs);
