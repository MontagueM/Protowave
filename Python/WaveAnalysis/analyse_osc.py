import numpy as np
import matplotlib.pyplot as plt
from scipy.optimize import curve_fit

def fft_osc_data(path, plot=False):
  f = open(path, "r").readlines()[1:]
  x = np.zeros(len(f),)
  y = np.zeros(len(f),)
  min_x = 0
  for i, k in enumerate(f):
    s = k.strip().split(',')
    if i == 0:
      min_x = np.float(s[0])
    x[i] = np.float(s[0]) - min_x
    y[i] = np.float(s[1])


  yf = np.fft.fftshift(np.fft.fft(y))
  yf = np.fft.fft(y)
  time_sample = np.mean([x[i+1]-x[i] for i in range(len(x)-1)])

  x_fft = np.fft.fftfreq(len(x), time_sample)

  data = {x_fft[i]: yf[i] for i in range(len(x_fft))}
  newdata = {}
  for a, b in data.items():
    if 0 < a < 600:
      newdata[a] = b
  xf = list(newdata.keys())
  y_f = list(newdata.values())
  plot = True
  if plot:
    #plt.plot(x_fft, 2.0/len(x_fft) * np.abs(yf), label = 'Saw at 440 Hz')
    # plt.ylabel('FFT amplitude')
    plt.ylabel('Voltage /V')
    plt.xlabel('Time /s')
    plt.plot(x, y)
    plt.savefig("Graphs/PlotSaw440Hz.png")
    plt.show()
  return xf, 2.0/len(x_fft) * np.abs(y_f)
  

def gauss_function(x, a, x0, sigma):
    return a*np.exp(-(x-x0)**2/(2*sigma**2))


def gaussian_fit(xf, yf, plot=True):
  mean = np.mean(xf)
  sigma = np.std(xf)
  
  try:
    popt, pcov = curve_fit(gauss_function, xf, yf, p0 = [1, mean, sigma], maxfev=10000)
  except RuntimeError:
    return 0
  peak = popt[1]
  peak_acc = np.sqrt(pcov[1][1])
  newxf = np.linspace(min(xf), max(xf), 10000)
  if plot:
    plt.plot(newxf, gauss_function(newxf, *popt), label=f'Gauss Fit with peak at {peak:.2f} ± {peak_acc:.2f} Hz')
    plt.legend()
    plt.xlim([0,1000])
    plt.ylim([0, 0.65])
    plt.show()
  else:
    return peak




def fft_phone_data():
  pass

