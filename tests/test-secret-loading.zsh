source "$1/packages/zsh/.config/zsh/secret-loader.zsh"
typeset test_root="$2"

function fail() {
    print -u2 -- "FAIL (Zsh): $*"
    exit 1
}

for backend in keychain pass; do
    reference=example-service
    [[ "$backend" == pass ]] && reference=api/example
    unset DOTFILES_TEST_LOADED_SECRET
    export DOTFILES_TEST_SECRET_MODE=ok
    dotfiles_load_secret DOTFILES_TEST_LOADED_SECRET "$backend" "$reference" >"$test_root/stdout" || fail 'successful backend lookup failed'
    [[ "$DOTFILES_TEST_LOADED_SECRET" == 'fixture value with spaces' ]] || fail 'credential changed or metadata included'
    [[ ! -s "$test_root/stdout" ]] || fail 'helper printed a credential'
    /bin/sh -c '[ "$DOTFILES_TEST_LOADED_SECRET" = "fixture value with spaces" ]' || fail 'credential was not exported'

    export DOTFILES_TEST_LOADED_SECRET=inherited
    export DOTFILES_TEST_SECRET_MODE=fail
    dotfiles_load_secret DOTFILES_TEST_LOADED_SECRET "$backend" "$reference" || fail 'inherited credential was not accepted'
    [[ "$DOTFILES_TEST_LOADED_SECRET" == inherited ]] || fail 'inherited credential was overwritten'

    for mode in fail empty; do
        unset DOTFILES_TEST_LOADED_SECRET
        export DOTFILES_TEST_SECRET_MODE="$mode"
        if dotfiles_load_secret DOTFILES_TEST_LOADED_SECRET "$backend" "$reference" >"$test_root/stdout"; then
            fail 'missing or failed lookup succeeded'
        fi
        (( ${+DOTFILES_TEST_LOADED_SECRET} == 0 )) || fail 'failed lookup exported a value'
        [[ ! -s "$test_root/stdout" ]] || fail 'failed lookup printed a value'
    done
done

dotfiles_load_secret 'INVALID-NAME' keychain example-service
[[ $? == 2 ]] || fail 'invalid variable name was accepted'
dotfiles_load_secret DOTFILES_TEST_LOADED_SECRET unknown example-service
[[ $? == 2 ]] || fail 'unknown backend was accepted'

export PATH="$test_root/empty"
dotfiles_load_secret DOTFILES_TEST_LOADED_SECRET keychain example-service
[[ $? == 1 ]] || fail 'missing backend was accepted'
print -- 'Zsh secret loading: passed'
