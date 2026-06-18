from std.collections import List
from std.os.process import Process
from std.sys import argv
from std.subprocess import run


comptime DEFAULT_TIMEOUT = "10s"


def print_help():
    print("ooboo: Boo-backed agent control CLI")
    print("")
    print("usage:")
    print("  ooboo --help")
    print("  ooboo run-shell [--timeout DURATION] <command>")
    print("  ooboo codex <command> [arguments]")
    print("")
    print("commands:")
    print(
        "  run-shell         run one shell command through a temporary Boo"
        " session"
    )
    print("  codex start       start or reuse a Codex session")
    print("  codex wait-idle   wait until Codex stops producing output")
    print("  codex prompt      send a prompt to Codex")
    print("  codex peek        print the current session screen")
    print("  codex attach      attach to the session")
    print("  codex stop        stop the session")


def print_run_shell_help():
    print("ooboo run-shell: run one command through a temporary Boo shell")
    print("")
    print("usage:")
    print("  ooboo run-shell [--timeout DURATION] <command>")
    print("")
    print("examples:")
    print('  ooboo run-shell "printf hello"')
    print('  ooboo run-shell --timeout 500ms "sleep 2"')


def shell_quote(value: String) -> String:
    return "'" + value.replace("'", "'\\''") + "'"


def json_string(value: String) -> String:
    var escaped = value.replace("\\", "\\\\")
    escaped = escaped.replace('"', '\\"')
    escaped = escaped.replace("\n", "\\n")
    escaped = escaped.replace("\r", "\\r")
    escaped = escaped.replace("\t", "\\t")
    return '"' + escaped + '"'


def bool_json(value: Bool) -> String:
    if value:
        return "true"
    return "false"


def exit_code(mut process: Process) raises -> Int:
    var status = process.wait()
    if status.exit_code:
        return status.exit_code.value()
    return -1


def run_argv(path: String, args: List[String]) raises -> Int:
    var process = Process.run(path, args)
    return exit_code(process)


def run_boo(args: List[String]) raises -> Int:
    return run_argv("boo", args)


def boo_new(session: String) raises -> Int:
    var args = List[String]()
    args.append("new")
    args.append(session)
    args.append("-d")
    args.append("--")
    args.append("sh")
    return run_boo(args)


def boo_send(session: String, payload: String) raises -> Int:
    var args = List[String]()
    args.append("send")
    args.append(session)
    args.append("--text")
    args.append(payload)
    args.append("--enter")
    return run_boo(args)


def boo_wait_idle(session: String, timeout: String) raises -> Int:
    var args = List[String]()
    args.append("wait")
    args.append(session)
    args.append("--idle")
    args.append("--timeout")
    args.append(timeout)
    return run_boo(args)


def boo_kill(session: String) raises -> Int:
    var args = List[String]()
    args.append("kill")
    args.append(session)
    return run_boo(args)


def join_command_args(start: Int) -> String:
    args = argv()
    var command = String(args[start])
    for i in range(start + 1, len(args)):
        command += " "
        command += String(args[i])
    return command


def run_shell(command: String, timeout: String) raises:
    var session = "ooboo-run-shell"

    var new_code = boo_new(session)

    var payload = command
    payload += "\n__ooboo_status=$?"
    payload += "\nprintf '\\n__OOBOO_EXIT:%s__\\n' \"$__ooboo_status\""

    var send_code = boo_send(session, payload)
    var wait_code = boo_wait_idle(session, timeout)
    var wait_ok = wait_code == 0

    # Process.run currently exposes status but not captured stdout; keep capture isolated.
    var peek_json = run("boo peek " + shell_quote(session) + " --json")
    var cleanup_code = boo_kill(session)

    var timed_out = not wait_ok
    var has_exit_marker = wait_ok and peek_json.find("__OOBOO_EXIT:") != -1
    var command_ok = wait_ok and peek_json.find("__OOBOO_EXIT:0__") != -1
    var ok = command_ok and not timed_out
    var status = String("success")
    if timed_out:
        status = "timeout"
    elif not command_ok:
        status = "failure"

    print("{")
    print('  "ok": ' + bool_json(ok) + ",")
    print('  "status": ' + json_string(status) + ",")
    print('  "timed_out": ' + bool_json(timed_out) + ",")
    print('  "detected_exit": ' + bool_json(has_exit_marker) + ",")
    print('  "command_succeeded": ' + bool_json(command_ok) + ",")
    print('  "session": ' + json_string(session) + ",")
    print('  "command": ' + json_string(command) + ",")
    print('  "new_exit_code": ' + String(new_code) + ",")
    print('  "send_exit_code": ' + String(send_code) + ",")
    print('  "wait_exit_code": ' + String(wait_code) + ",")
    print('  "cleanup_exit_code": ' + String(cleanup_code) + ",")
    print('  "cleanup": ' + json_string("killed") + ",")
    print('  "boo_peek": ' + peek_json)
    print("}")


def handle_run_shell() raises:
    args = argv()
    if len(args) <= 2:
        print_run_shell_help()
        return

    if args[2] == "--help" or args[2] == "-h":
        print_run_shell_help()
        return

    var timeout = String(DEFAULT_TIMEOUT)
    var command_start = 2
    if args[2] == "--timeout":
        if len(args) <= 4:
            print("missing command after --timeout")
            return
        timeout = String(args[3])
        command_start = 4

    run_shell(join_command_args(command_start), timeout)


def main() raises:
    args = argv()
    if len(args) <= 1:
        print_help()
        return

    first = args[1]
    if first == "--help" or first == "-h":
        print_help()
        return

    if first == "run-shell":
        handle_run_shell()
        return
    elif first == "codex":
        print("codex commands are not implemented yet")
        return

    print("unknown command: " + first)
