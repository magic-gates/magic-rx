from cocotb.triggers import RisingEdge
from cocotb.clock import Clock
import cocotb
import numpy as np
import matplotlib.pyplot as plt

FFT_LEN = 1024
CP_LEN = 64
N_SYM = 400
N_PILOT = 64
QAM_ORDER = 4
SKIP_SYM = 100

GB = 1
PILOT_SC = np.arange(N_PILOT) * (FFT_LEN // N_PILOT)
DATA_SC = np.concatenate((
    np.arange(1, FFT_LEN / 2 - GB, dtype=int),
    np.arange(FFT_LEN / 2 + GB, FFT_LEN, dtype=int)
))
DATA_SC = DATA_SC[~np.isin(DATA_SC, PILOT_SC)]

@cocotb.test()
async def test(dut):
    Clock(dut.clk, 10, unit="ns").start()
    await reset(dut)

    pilots = load_pilots("pilots.mem")

    cocotb.start_soon(tx(dut, N_SYM, pilots));

    captured = await rx(dut)

    plot(captured)

async def rx(dut):
    rx_sym = 0
    last_idx = -1

    captured = []

    while rx_sym < N_SYM - 1:
        await RisingEdge(dut.clk)

        if dut.o_ce.value == 1:
            idx = dut.o_idx.value.to_unsigned()

            if idx != last_idx and idx == FFT_LEN - 1:
                rx_sym += 1
            last_idx = idx

            if idx in DATA_SC and rx_sym > SKIP_SYM:
                re = dut.o_re.value.to_signed()
                im = dut.o_im.value.to_signed()
                captured.append(complex(re, im))

    return np.array(captured)

async def tx(dut, n_sym, pilots):
    tx_signal = np.array([], dtype=complex)

    for _ in range(n_sym):
        f_symbol = np.zeros(FFT_LEN, dtype=complex)

        f_symbol[DATA_SC] = generate_64qam(len(DATA_SC))
        f_symbol[PILOT_SC] = pilots

        t_symbol = np.fft.ifft(f_symbol)
        cp = t_symbol[-CP_LEN:]
        full_symbol = np.concatenate([cp, t_symbol])
        tx_signal = np.concatenate((tx_signal, full_symbol))

    tx_signal = apply_cfo(tx_signal, 0.2)
    tx_signal = apply_paths(tx_signal, [1.0, 0.3 + 0.2j, 0.1j])
    tx_signal = apply_awgn(tx_signal, 27)
    tx_signal = tx_signal * 16384

    for sample in tx_signal:
        dut.i_re.value = int(np.clip(sample.real, -2048, 2047))
        dut.i_im.value = int(np.clip(sample.imag, -2048, 2047))
        await RisingEdge(dut.clk)

def apply_awgn(signal, snr_db):
    sig_pwr = np.mean(np.abs(signal)**2)
    noise_pwr = sig_pwr / (10**(snr_db / 10))
    noise = np.sqrt(noise_pwr / 2) * (np.random.randn(len(signal)) + 1j * np.random.randn(len(signal)))
    return signal + noise

def apply_cfo(signal, cfo):
    t = np.arange(len(signal))
    return signal * np.exp(1j * 2 * np.pi * cfo * t / FFT_LEN)

def apply_paths(signal, taps):
    return np.convolve(signal, taps, mode='same')

def plot(s):
    plt.figure(figsize=(10, 8))
    plt.hist2d(s.real, s.imag, bins=256, cmap='viridis')
    plt.colorbar(label='Density')
    plt.title(f"Constellation Heatmap")
    plt.xlabel("Re")
    plt.ylabel("Im")
    plt.grid(True, alpha=0.3)
    plt.show()
    plt.savefig("constallation.png")

def generate_64qam(size):
    """Generates normalized 64-QAM symbols."""
    # 64-QAM values: +/-1, +/-3, +/-5, +/-7
    qam_vals = np.array([-7, -5, -3, -1, 1, 3, 5, 7])
    re = np.random.choice(qam_vals, size)
    im = np.random.choice(qam_vals, size)
    syms = re + 1j * im
    # Average power of 64-QAM is 42, normalize to power = 1
    return syms / np.sqrt(42)

def generate_qpsk(n):
    symbols = np.array([1+0j, 1j, -1+0j, -1j])
    return np.random.choice(symbols, size=n)

def load_pilots(filename):
    mapping = {'00': 1+0j, '01': 0+1j, '10': -1+0j, '11': 0-1j}
    pilots = []
    with open(filename, 'r') as f:
        for line in f:
            line = line.strip()
            if line in mapping:
                pilots.append(mapping[line])
    return np.array(pilots)

def bit_reverse(num, bits):
    return int(f"{num:0{bits}b}"[::-1], 2)

def reverse_array(a):
    n = len(a)
    bits = (n - 1).bit_length()

    result = np.zeros_like(a)
    for i, v in enumerate(a):
        r = bit_reverse(i, bits)
        result[r] = v
    return result

async def reset(dut):
    dut.arst.value = 1
    dut.i_re.value = 0
    dut.i_im.value = 0
    await RisingEdge(dut.clk)
    dut.arst.value = 0
