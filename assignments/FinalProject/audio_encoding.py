import math

def parse_note_line(line):
    """
    Parse a line like 'C#4', 'Eb3', 'A4', or 'R'/'REST'.
    Returns (note, octave) or ('REST', None).
    """
    line = line.strip()

    # Handle rests
    if line.upper() in ["R", "REST"]:
        return ("REST", None)

    # Note is letters and accidentals, octave is last characters
    note_part = ""
    octave_part = ""

    for char in line:
        if char.isdigit() or (char == '-' and not octave_part):
            octave_part += char
        else:
            note_part += char

    if not octave_part:
        raise ValueError(f"Missing octave in note: {line}")

    return (note_part, int(octave_part))


def note_to_frequency(note, octave):
    """
    Convert a single note+octave into a frequency (Hz).
    Rests return 0.0.
    """
    if note == "REST":
        return 0.0

    semitone_map = {
        "C": 0, "C#": 1, "Db": 1,
        "D": 2, "D#": 3, "Eb": 3,
        "E": 4,
        "F": 5, "F#": 6, "Gb": 6,
        "G": 7, "G#": 8, "Ab": 8,
        "A": 9, "A#": 10, "Bb": 10,
        "B": 11
    }

    if note not in semitone_map:
        raise ValueError(f"Invalid note name: {note}")

    midi_number = 12 * (octave + 1) + semitone_map[note]
    freq = 440 * (2 ** ((midi_number - 69) / 12))
    return freq


def load_notes_from_file(filename):
    """
    Reads a file where each line is a note (e.g., C#4) or rest.
    Returns a list of frequencies.
    """
    frequencies = []

    with open(filename, "r") as f:
        for line in f:
            if not line.strip():
                continue  # skip empty lines

            note, octave = parse_note_line(line)
            freq = note_to_frequency(note, octave)
            frequencies.append(freq)

    return frequencies


def write_frequencies_to_file(frequencies, output_filename):
    """
    Writes a list of frequencies to a file, one per line.
    """
    with open(output_filename, "w") as f:
        for freq in frequencies:
            freq = int(freq)
            if freq != 0:
                freq = max((256-freq)+1, 10)
            f.write(f"{freq:x}\n")


# Example usage:
if __name__ == "__main__":
    input_file = "merrychristmas.txt"
    output_file = "mcmidi.txt"

    freqs = load_notes_from_file(input_file)
    write_frequencies_to_file(freqs, output_file)

    print(f"Frequencies written to '{output_file}'")
