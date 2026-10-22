# Usage: dotfiles_load_secret VARIABLE keychain SERVICE | VARIABLE pass ENTRY
function dotfiles_load_secret() {
    emulate -L zsh
    unsetopt XTRACE VERBOSE
    (( $# == 3 )) || return 2
    local variable="$1" backend="$2" reference="$3" secret_value
    [[ "$variable" =~ '^[A-Z_][A-Z0-9_]*$' ]] || return 2

    # An explicit environment value wins over the password store.
    [[ -n "${(P)variable}" ]] && return 0

    case "$backend" in
        keychain)
            (( $+commands[security] )) || return 1
            secret_value="$(command security find-generic-password -a "$USER" -s "$reference" -w 2>/dev/null)" || return 1
            ;;
        pass)
            (( $+commands[pass] )) || return 1
            secret_value="$(command pass show "$reference" 2>/dev/null)" || return 1
            # pass entries may contain notes after the first line.
            secret_value="${secret_value%%$'\n'*}"
            ;;
        *) return 2 ;;
    esac

    [[ -n "$secret_value" && "$secret_value" != *$'\n'* ]] || return 1
    export "$variable=$secret_value"
}
