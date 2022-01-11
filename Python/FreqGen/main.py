import matplotlib.pyplot as plt
import numpy as np
from scipy.interpolate import CubicSpline



scale_dict = {
  "Min": [0, 2, 3, 5, 7, 8, 10, 12,
          12, 14, 15, 17, 19, 20, 22, 24],
  "Maj": [0, 2, 4, 5, 7, 9, 11, 12,
          12, 14, 16, 17, 19, 21, 23, 24]
}      

key_to_number = {
  "A": 0,
  "A#": 1,
  "B": 2,
  "C": 3,
  "C#": 4,
  "D": 5,
  "D#": 6,
  "E": 7,
  "F": 8,
  "F#": 9,
  "G": 10,
  "G#": 11
}

note_array_canon = [
  "F#4",
  "E4",
  "D4",
  "C#4",
  "B4",
  "A4",
  "B4",
  "C#4",
]

note_array_jingle = [
  "E4",
  "G4",
  "C4",
  "D4",
  "E4",
  "F4",
  "E4",
  "D4",
  "E4",
  "D4",
  "G4",
]

def frequency_conv(n, base=440):
  return base*2**(n/12)

def find_ccp_value_from_frequency(frequency, plot=True):
  x = [441.732, 440.169, 1953, 1984, 243.68, 162.565, 486.381, 776.3, 1544.18, 1106.42, 862.412, 969.058, 1288.31, 3784.12]
  y = [0x11a, 0x11b, 0x3f, 0x3e, 0x200, 0x300, 0x100, 0xa0, 0x50, 0x70, 0x90, 0x80, 0x60, 0x20]

  x, y =  zip(*sorted(zip(x, y)))
  #plt.plot(x, y)
  #plt.show()
  p = CubicSpline(x, y)
  
  #print(p(523.25))
  if plot:
    fit_x = np.linspace(0, 3800, 100000)
    fit_y = p(fit_x)
    plt.plot(fit_x, fit_y, label = 'fit')
    plt.scatter(x, y, label='data', color='red')
    plt.ylabel('Compare value for the CCP module')
    plt.xlabel('Frequency / Hz')
    plt.legend()
    # plt.show()
  return p(frequency).tolist()

def convert_scales():
  val = hex(round(find_ccp_value_from_frequency(220)))

  for scale, vals in scale_dict.items():
    for i, val in enumerate(vals):
      freq = frequency_conv(val, 440)
      ccp = find_ccp_value_from_frequency(freq)
      scale_dict[scale][i] = hex(round(ccp))
      scale_dict[scale][i] = round(freq)
      print(round(freq), hex(round(ccp)))
  
  print(scale_dict)

def convert_hex_asm(in_hex):
  s = in_hex[2:]
  if len(s) == 2:
    a = "00"
  else:
    a = s[:-2]
  b = s[-2:]
  string = f'db      0x{b}, 0x{a}'
  return string

def convert_note_array():
  for x in note_array_jingle:
    key = x[:-1]
    octave = int(x[-1])
    #print(key, octave)
    value = key_to_number[key]
    freq = frequency_conv(value, 440)*(octave-3)
    ccp = find_ccp_value_from_frequency(freq)
    fin = hex(round(ccp))
    print(fin)
    conv = convert_hex_asm(fin)
    print(conv)

if __name__ == "__main__":
  # convert_scales()
  convert_note_array()