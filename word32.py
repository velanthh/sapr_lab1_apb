import argparse


def format_word(value):
    """Return an unsigned 32-bit value as an eight-digit hexadecimal word."""
    if not 0 <= value <= 0xFFFFFFFF:
        raise ValueError("value must fit in an unsigned 32-bit word")
    return f"0x{value:08X}"


def pack_ascii(value):
    """Pack four ASCII characters with the first character in the high byte."""
    if len(value) != 4 or not value.isascii():
        raise ValueError("exactly four ASCII characters are required")
    return int.from_bytes(value.encode("ascii"), byteorder="big")


def main():
    parser = argparse.ArgumentParser(description="Format a 32-bit word.")
    parser.add_argument("value", help="integer or four ASCII characters")
    parser.add_argument("--ascii", action="store_true", help="pack ASCII characters")
    args = parser.parse_args()
    try:
        value = pack_ascii(args.value) if args.ascii else int(args.value, 0)
        print(format_word(value))
    except ValueError as error:
        parser.error(str(error))


if __name__ == "__main__":
    main()
