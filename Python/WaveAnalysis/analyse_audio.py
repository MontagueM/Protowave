# This file converts .aac into amplitude vs time, then finds FFT primary peak for each time and plots it
import scipy.io.wavfile
import matplotlib.pyplot as plt
import analyse_osc
import numpy as np


def get_freq_from_instant(data, t, samplerate):
  # Select a tiny region to sample for fourier transform
  pm = 5000
  #t += samplerate*5
  t = int(t)+pm
  if t+pm >= len(data)-1:
    return 0
  sd = data[t-pm:t+pm]
  yf = np.fft.fft(sd)
  x_fft = np.fft.fftfreq(pm*2, 1/samplerate)
  yf = 2.0/len(x_fft) * np.abs(yf)

  try:
    data = {x_fft[i]: yf[i] for i in range(len(x_fft))}
  except IndexError:
    return 0
  newdata = {}
  for a, b in data.items():
    if 0 < a < 1000:
      newdata[a] = b
  xf = list(newdata.keys())
  yf = list(newdata.values())

  mind = yf.index(max(yf))

  freq_peak = analyse_osc.gaussian_fit(xf, yf, plot=False)

  # print(t/samplerate, mind, max(yf), xf[mind], freq_peak)
  # plt.plot(xf, yf)
  # plt.show()
  
  return freq_peak


def get_freq_array_from_staircase(samplerate, data):
  # Given a frequency vs time plot of a staircase of frequencies, try and identify the plateaus with their freq
  freq_arr = []
  var_lim = 1
  val_hist = []
  for i, x in enumerate(data):
    if len(val_hist):
      m = np.mean(val_hist)
      if len(freq_arr) > 0:
        if x < freq_arr[-1][0] + 10:
          val_hist = []
          continue
      if m - var_lim <= x <= m + var_lim:
        val_hist.append(x)
      else:
        val_hist = []
        continue
    else:
      val_hist.append(x)
      continue
    #if len(val_hist) != 0:
    #  print(len(val_hist))
    if len(val_hist) > 5:  # 0.1 seconds
      freq_arr.append([np.mean(val_hist), np.std(val_hist)])
      val_hist = []
  return freq_arr

def analyse(fname, plot=True):
  # Get data
  samplerate, data = scipy.io.wavfile.read(fname)
  duration = len(data) / samplerate
  time = np.arange(0, duration, 1/samplerate)
  
  ts = np.linspace(0, duration, 500)
  s = np.linspace(0, len(data), 500)
  fs = []
  for i, t in enumerate(s):
    print(f'{i+1}/{len(s)}')
    f = get_freq_from_instant(data, t, samplerate)
    if f < 0 or f > 1000:
      f = 0
    fs.append(f)
  
  d = get_freq_array_from_staircase(samplerate, fs)
  [print(x) for x in d]
  plot = True
  if plot:
    #plt.plot(time, abs(data))
    plt.xlabel('Time / s')
    plt.ylabel('Frequency / Hz')

    plt.plot(ts, fs)
    plt.title(fname)
    plt.show()