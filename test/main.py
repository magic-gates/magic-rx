import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer
import numpy as np
import matplotlib.pyplot as plt

# --- Test Parameters ---
N_FFT = 1024
CP_LEN = 64
QAM_ORDER = 4  # Options: 4, 16, 64, 256
CFO_UNIT = 0.4 # Frequency offset in subcarrier units
SNR_DB = 27
MULTIPATH_TAPS = [1.0] # Example multipath 0.3 + 0.2j, 0.1j
SKIP_SYMBOLS = 100 # Skip initial symbols for acquisition
NUM_SYMBOLS = 1000 # Total symbols to simulate
DATA_SUBCARRIERS = np.arange(0, 1024) # Define indices for data
DATA_SUBCARRIERS = DATA_SUBCARRIERS[(DATA_SUBCARRIERS % 32 != 0)]

def bit_reverse(n, bits):
    return int('{:0{b}b}'.format(n, b=bits)[::-1], 2)

def generate_qam_symbols(num_symbols, order):
    """Generates random QAM symbols normalized to appropriate range."""
    m = int(np.sqrt(order))
    nodes = np.arange(m) - (m - 1) / 2
    x, y = np.meshgrid(nodes, nodes)
    constellation = (x + 1j * y).flatten()
    # Normalize power to 1
    constellation /= np.sqrt(np.mean(np.abs(constellation)**2))
    return np.random.choice(constellation, num_symbols)

def apply_channel(signal, snr_db, cfo, taps):
    """Applies AWGN, CFO, and Multipath effects."""
    # 1. Multipath
    signal = np.convolve(signal, taps, mode='same')

    # 2. CFO (Continuous phase rotation)
    t = np.arange(len(signal))
    signal *= np.exp(1j * 2 * np.pi * cfo * t / N_FFT)

    # 3. AWGN
    sig_pwr = np.mean(np.abs(signal)**2)
    noise_pwr = sig_pwr / (10**(snr_db / 10))
    noise = np.sqrt(noise_pwr / 2) * (np.random.randn(len(signal)) + 1j * np.random.randn(len(signal)))
    return signal + noise

@cocotb.test()
async def test_ofdm_receiver(dut):
    # 1. Setup Clock
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())

    # 2. Generate OFDM Signal
    total_samples = (N_FFT + CP_LEN) * NUM_SYMBOLS
    time_domain_signal = np.array([], dtype=complex)

    for _ in range(NUM_SYMBOLS):
        # Create symbol in freq domain
        freq_syms = np.zeros(N_FFT, dtype=complex)
        freq_syms[DATA_SUBCARRIERS] = generate_qam_symbols(len(DATA_SUBCARRIERS), QAM_ORDER)

        # IFFT to time domain
        time_sym = np.fft.ifft(freq_syms) * np.sqrt(N_FFT)
        # Add CP
        cp = time_sym[-CP_LEN:]
        full_sym = np.concatenate([cp, time_sym])
        time_domain_signal = np.concatenate([time_domain_signal, full_sym])

    # Apply Channel Effects
    rx_signal = apply_channel(time_domain_signal, SNR_DB, CFO_UNIT, MULTIPATH_TAPS)

    # Scale to 12-bit signed (range -2048 to 2047)
    # Target an RMS that avoids clipping (e.g., scale factor 400)
    rx_signal_scaled = rx_signal * 1024

    # 3. Drive DUT
    dut.arst.value = 1
    dut.i_re.value = 0
    dut.i_im.value = 0
    await Timer(100, unit="ns")
    await RisingEdge(dut.clk)
    dut.arst.value = 0

    # Feed some noise initially to stabilize pipeline
    for _ in range(50):
        dut.i_re.value = int(np.random.normal(0, 5))
        dut.i_im.value = int(np.random.normal(0, 5))
        await RisingEdge(dut.clk)

    # 4. Monitor and Plotting Data
    captured_symbols = []
    symbol_count = 0
    samples_processed = 0

    async def monitor_output():
        nonlocal symbol_count
        current_symbol_idx = -1
        last_idx = -1

        while samples_processed < len(rx_signal_scaled):
            await RisingEdge(dut.clk)
            if dut.o_ce.value == 1:
                # Bit-reverse the index back to natural order
                raw_idx = dut.o_idx.value.to_unsigned()
                natural_idx = bit_reverse(raw_idx, 10)

                # Detect new symbol boundaries based on index wrap-around
                if raw_idx < last_idx:
                    symbol_count += 1
                last_idx = raw_idx

                # Skip initial symbols and filter for data subcarriers
                if symbol_count >= SKIP_SYMBOLS:
                    if natural_idx in DATA_SUBCARRIERS:
                        re = dut.o_re.value.to_signed()
                        im = dut.o_im.value.to_signed()
                        captured_symbols.append(complex(re, im))

    # Run monitor in background
    mon_task = cocotb.start_soon(monitor_output())

    # Feed signal to DUT
    for sample in rx_signal_scaled:
        dut.i_re.value = int(np.clip(sample.real, -2048, 2047))
        dut.i_im.value = int(np.clip(sample.imag, -2048, 2047))
        await RisingEdge(dut.clk)
        samples_processed += 1

    # Wait for remaining data to clear pipeline
    await Timer(2000, unit="ns")

    # 5. Visualization
    if captured_symbols:
        re_vals = [s.real for s in captured_symbols]
        im_vals = [s.imag for s in captured_symbols]

        plt.figure(figsize=(8, 8))
        plt.hist2d(re_vals, im_vals, bins=256, cmap='viridis')
        # plt.colorbar(label='Density')
        plt.title(f"Constellation Heatmap ({QAM_ORDER}-QAM)\nCFO={CFO_UNIT}, SNR={SNR_DB}dB")
        plt.xlabel("In-Phase")
        plt.ylabel("Quadrature")
        plt.grid(True, alpha=0.3)
        plt.show()
        plt.savefig("constellation_heatmap.png")
        dut._log.info("Heatmap saved to constellation_heatmap.png")
    else:
        dut._log.error("No data captured!")
