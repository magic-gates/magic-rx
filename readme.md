# Magic OFDM receiver
Compact unidirectional (no feedback) OFDM receiver for educational and further development purposes. It is supposed to be a part of the Proof of Concept Magic video link.

## Why this architecture
I exploit the fact, that the video signal is continuous and periodic, and therefore normally never interrupted. This leads to many attractive simplifications.

## TODO
- [x] Basic timing and FFO synchronization
- [x] Radix-2^2 SDF 1024-point FFT
- [ ] LS estimator and linear interpolator
- [ ] Regularized ZF equalizer
- [ ] Run it on an FPGA and prove it works
- [ ] Verify performance
