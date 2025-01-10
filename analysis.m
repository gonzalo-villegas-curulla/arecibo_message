%% [1] USING fmdemod()
clc, clear;
[x,fs] = audioread('The_Arecibo_Message.wav');

fc       = 1000;          % Carrier frequency in Hz
fdev     = 10;       % Frequency deviation in Hz (assumed, can be tuned)
bit_rate = 10;      % Bits per second (known from Arecibo message)
Nbits    = 1679;    % Expected number of bits in the Arecibo message

samples_per_bit = fs / bit_rate;
t = [0:length(x)-1]' / fs;

% FM demodulation
% demodulated_signal = fmdemod(x, fc, fs, fdev);
xh                 = hilbert(x).*exp(-i*2*pi*fc*t);
demodulated_signal = (1/(2*pi*fdev))*[zeros(1,size(xh,2)); diff(unwrap(angle(xh)))*fs];

% Low-pass filt the high-frequency noise
LPfilt_obj = designfilt('lowpassfir', 'PassbandFrequency', bit_rate, ...
                    'StopbandFrequency', bit_rate*1.5, 'SampleRate', fs);
filtered_signal = filtfilt(LPfilt_obj, demodulated_signal);

% Normalize the signal 
normalized_signal = filtered_signal - min(filtered_signal);
normalized_signal = normalized_signal / max(normalized_signal);


% Sample the signal at the bit rate to get binary digits
sample_idxs  = round(samples_per_bit * (0:Nbits-1) + samples_per_bit / 2);

thres = median(normalized_signal(1:end/2)) + 1*std(normalized_signal(1:end/2));
binary_sequence = normalized_signal(sample_idxs) > thres;


% Reshape and visualize the message
message_matrix = reshape(binary_sequence, 23, 73);
figure;
imagesc(abs(message_matrix'-1));
% imshow(abs(message_matrix'-1));
colormap(gray);

%% [2] USING hilbert, instfreq and filter
clc, clear;
[x,fs]=audioread('The_Arecibo_Message.wav');

fc       = 1000;    % Carrier [Hz]
bit_rate = 10;      % Bits per second
Nbits    = 1679;    % Number of bits in the message

dt       = 1/fs;
samples_per_bit = fs / bit_rate;

% Remove carrier frequency using a band-pass filter
PBfilt_obj = designfilt('bandpassfir', 'FilterOrder', 100, ...
    'CutoffFrequency1', fc - 20, 'CutoffFrequency2', fc + 20, 'SampleRate', fs);
x_filtered = filtfilt(PBfilt_obj, x);

% Step 2: Compute instantaneous phase
analytic_signal = hilbert(x_filtered);        % Analytic signal
inst_phase = unwrap(angle(analytic_signal));  % Unwrap the phase

% Differentiate phase to get frequency variations (demodulation)
inst_freq = diff(inst_phase)/dt * 1/(2*pi);

% Low-pass filter the frequency variations to remove noise
SBfilt_obj = designfilt('lowpassfir', 'PassbandFrequency', bit_rate, ...
    'StopbandFrequency', bit_rate * 1.5, 'SampleRate', fs);
demodulated_signal = filtfilt(SBfilt_obj, inst_freq);

% Normalize the signal and extract bits by thresholding
normalized_signal = demodulated_signal - min(demodulated_signal);
normalized_signal = normalized_signal / max(normalized_signal);

threshold = median(normalized_signal(1:end/2)) + 1*std(normalized_signal(1:end/2));
binary_sequence = normalized_signal > threshold;

% Resample at bit intervals
sample_idxs = round(samples_per_bit * (0:Nbits-1) + samples_per_bit / 2);
binary_sequence_resampled = binary_sequence(sample_idxs);

% Reshape and visualize the message
message_matrix = reshape(binary_sequence_resampled, 73, 23);
imagesc(message_matrix);
colormap(gray);



%%  USING x_baseband, hilbert and INSTANTANEOUS FREQUENCY ==> Very unreliable 
% due to how instantaneous frequency is computed on the baseband signal

clc, clear;
[x,fs]=audioread('The_Arecibo_Message.wav');


% Parameters
fc       = 1000;    % Carrier frequency in Hz 
bit_rate = 10;      % Bits per second. 1679bits/t(end) = 10.00 bits/second
num_bits = 1679;    % Expected number of bits
fdev     = 10;

samples_per_bit = fs / bit_rate;

dt = 1/fs;
t  = (0:length(x)-1)' *dt;

% Mix down the signal (shift to baseband) ?????
x_baseband = x .* cos(2*pi*fc*t);

% Compute the phase of the analytic signal
% analytic_signal = hilbert(x_baseband);  % Hilbert transform
analytic_signal = hilbert(x_baseband).*exp(-1i*2*pi*fc*t)/(2*pi*fdev);
inst_phase      = unwrap(angle(analytic_signal));  % Unwrapped phase

% Compute instantaneous frequency (derivative of phase)
inst_freq = diff(inst_phase)/dt  * (1/(2 * pi)) ;



% lpFilt = designfilt('lowpassfir', 'PassbandFrequency', 2*fc+1.0*fdev, ...
%     'StopbandFrequency', 2*fc+2.0*fdev, 'SampleRate', fs);

BPfilt_obj = designfilt('bandpassfir','FilterOrder',20, ...
    'CutoffFrequency1', 2*fc-2.0*fdev, ...
    'CutoffFrequency2',2*fc+2*fdev,...
    'SampleRate', fs);

inst_freq = filtfilt(BPfilt_obj, inst_freq);


% Threshold the frequency to determine bit values
binary_sequence = inst_freq > 0; % rubbish?????????????

% Resample at bit intervals
sample_idxs               = round(samples_per_bit * (0:num_bits-1) + samples_per_bit / 2);
binary_sequence_resampled = binary_sequence(sample_idxs);
binary_sequence_resampled = abs(binary_sequence_resampled-1);

% Reshape and visualize the message
message_matrix = reshape(binary_sequence_resampled, 23, 73);
figure;
imagesc(message_matrix');
colormap(gray);


