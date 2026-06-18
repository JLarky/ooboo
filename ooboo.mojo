from std.sys import argv


def print_help():
    print("ooboo: Boo-backed agent control CLI")
    print("")
    print("usage:")
    print("  ooboo --help")
    print("  ooboo codex <command> [arguments]")
    print("")
    print("commands:")
    print("  codex start       start or reuse a Codex session")
    print("  codex wait-idle   wait until Codex stops producing output")
    print("  codex prompt      send a prompt to Codex")
    print("  codex peek        print the current session screen")
    print("  codex attach      attach to the session")
    print("  codex stop        stop the session")


def main() raises:
    args = argv()
    if len(args) <= 1:
        print_help()
        return

    first = args[1]
    if first == "--help" or first == "-h":
        print_help()
        return

    if first == "codex":
        print("codex commands are not implemented yet")
        return

    print("unknown command: " + first)
