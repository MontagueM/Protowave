import analyse_osc
import analyse_audio

if __name__ == "__main__":
  #name = "osc_data/P1_C2_07.CSV"
  #xf, yf = analyse_osc.fft_osc_data("osc_data/P1_C2_02.CSV", plot=True)
  #xg, yg = analyse_osc.gaussian_fit(xf, yf)
  analyse_audio.analyse("audio/Record-06_50.wav", True)