import argparse


def format_word(value):
    """Return an unsigned 32-bit value as an eight-digit hexadecimal word."""
    if not 0 <= value <= 0xFFFFFFFF:
        raise ValueError("value must fit in an unsigned 32-bit word")
    return f"0x{value:08X}"


def main():
    parser = argparse.ArgumentParser(description="Format a 32-bit word.")
    parser.add_argument("value", help="integer, for example 15 or 0x0F")
    args = parser.parse_args()
    try:
        print(format_word(int(args.value, 0)))
    except ValueError as error:
        parser.error(str(error))


if __name__ == "__main__":
    main()
