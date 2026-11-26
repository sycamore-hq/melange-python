"""Line I/O used by the Python target's Stdlib replacements."""


def print_endline(text: str) -> None:
    print(text, flush=True)
