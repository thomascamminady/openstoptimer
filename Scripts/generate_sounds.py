# /// script
# requires-python = ">=3.11"
# dependencies = [
#     "fire",
# ]
# ///
"""Synthesizes the bundled OpenStopTimer notification/beep sounds as WAV files.

Run via: uv run Scripts/generate_sounds.py generate
"""

from __future__ import annotations

import math
import struct
import wave
from pathlib import Path

import fire

SAMPLE_RATE = 44_100


def _envelope(t: float, duration: float, attack: float = 0.01, release: float = 0.03) -> float:
    """Linear fade-in/fade-out envelope, 0..1, to avoid audible clicks."""
    if t < attack:
        return t / attack
    if t > duration - release:
        return max(0.0, (duration - t) / release)
    return 1.0


def _tone(
    frequency: float,
    duration: float,
    amplitude: float = 0.6,
    start_frequency: float | None = None,
) -> list[float]:
    """Generates a sine tone, optionally sweeping from `start_frequency` to `frequency`."""
    sample_count = int(SAMPLE_RATE * duration)
    samples: list[float] = []
    for n in range(sample_count):
        t = n / SAMPLE_RATE
        if start_frequency is not None:
            progress = t / duration
            instantaneous_freq = start_frequency + (frequency - start_frequency) * progress
        else:
            instantaneous_freq = frequency
        phase = 2 * math.pi * instantaneous_freq * t
        value = math.sin(phase) * amplitude * _envelope(t, duration)
        samples.append(value)
    return samples


def _harmonic_bell(
    fundamental: float,
    duration: float,
    amplitude: float = 0.5,
) -> list[float]:
    """A bell-like tone: fundamental plus a few decaying overtones."""
    partials = [(1.0, 1.0), (2.0, 0.5), (2.76, 0.3), (4.0, 0.15)]
    sample_count = int(SAMPLE_RATE * duration)
    samples = [0.0] * sample_count
    for ratio, partial_amplitude in partials:
        freq = fundamental * ratio
        decay = 3.5 / duration
        for n in range(sample_count):
            t = n / SAMPLE_RATE
            envelope = math.exp(-decay * t) * _envelope(t, duration, attack=0.005, release=0.05)
            samples[n] += math.sin(2 * math.pi * freq * t) * amplitude * partial_amplitude * envelope
    peak = max(abs(s) for s in samples) or 1.0
    return [s / peak * amplitude for s in samples]


def _silence(duration: float) -> list[float]:
    return [0.0] * int(SAMPLE_RATE * duration)


def _write_wav(samples: list[float], path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(path), "w") as writer:
        writer.setnchannels(1)
        writer.setsampwidth(2)
        writer.setframerate(SAMPLE_RATE)
        frames = b"".join(
            struct.pack("<h", int(max(-1.0, min(1.0, sample)) * 32767)) for sample in samples
        )
        writer.writeframes(frames)


def _sounds() -> dict[str, list[float]]:
    return {
        "beepShort": _tone(frequency=880, duration=0.15, amplitude=0.9),
        "beepLong": _tone(frequency=880, duration=0.4, amplitude=0.9),
        "beepDouble": _tone(frequency=880, duration=0.12, amplitude=0.9)
        + _silence(0.08)
        + _tone(frequency=880, duration=0.12, amplitude=0.9),
        "chime": _tone(frequency=660, duration=0.18, amplitude=0.5)
        + _tone(frequency=880, duration=0.28, amplitude=0.5),
        "bell": _harmonic_bell(fundamental=523.25, duration=1.2),
        "whistle": _tone(frequency=1600, duration=0.3, amplitude=0.55, start_frequency=1000),
    }


class Commands:
    def generate(self, output_dir: str = "OpenStopTimer/Resources/Sounds") -> None:
        """Generates all bundled beep sounds as .wav files into `output_dir`."""
        destination = Path(output_dir)
        for name, samples in _sounds().items():
            _write_wav(samples, destination / f"{name}.wav")
            print(f"wrote {destination / f'{name}.wav'}")


if __name__ == "__main__":
    fire.Fire(Commands)
