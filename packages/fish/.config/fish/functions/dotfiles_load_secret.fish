function dotfiles_load_secret --description 'Export a named credential from Keychain or pass'
    # Keep credential values out of Fish tracing output.
    set -l fish_trace
    if test (count $argv) -ne 3
        return 2
    end
    set -l variable "$argv[1]"
    set -l backend "$argv[2]"
    set -l reference "$argv[3]"
    string match -qr '^[A-Z_][A-Z0-9_]*$' -- "$variable"; or return 2

    # An explicit environment value wins over the password store.
    if set -q $variable; and test -n "$$variable"
        return 0
    end

    set -l secret_value
    switch "$backend"
        case keychain
            command -q security; or return 1
            set secret_value (command security find-generic-password -a "$USER" -s "$reference" -w 2>/dev/null)
            or return 1
        case pass
            command -q pass; or return 1
            set secret_value (command pass show "$reference" 2>/dev/null)
            or return 1
            # pass entries may contain notes after the first line.
            set secret_value $secret_value[1]
        case '*'
            return 2
    end

    if test (count $secret_value) -ne 1; or test -z "$secret_value"
        return 1
    end
    set -gx $variable "$secret_value"
end
