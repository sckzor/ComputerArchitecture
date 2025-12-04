def duplicate_non_rest(input_file, output_file):
    """
    Reads notes from input_file and writes them to output_file,
    duplicating every note that is not a rest.
    """
    with open(input_file, "r") as fin, open(output_file, "w") as fout:
        for line in fin:
            note = line.strip()
            if not note:
                continue  # skip empty lines

            # Check rest
            if note.upper() in ("R", "REST"):
                fout.write(note + "\n")  # keep single rest
            else:
                fout.write(note + "\n")
                fout.write(note + "\n")  # duplicate non-rest notes


# Example usage:
if __name__ == "__main__":
    duplicate_non_rest("landlnotes.txt", "merrychristmas.txt")
    print("Done! Output written to notes_duplicated.txt")
