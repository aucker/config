source "$argv[1]/packages/fish/.config/fish/functions/dotfiles_load_secret.fish"
set -l test_root "$argv[2]"

function fail
    printf 'FAIL (Fish): %s\n' "$argv" >&2
    exit 1
end

for backend in keychain pass
    set -l reference example-service
    if test "$backend" = pass
        set reference api/example
    end
    set -e DOTFILES_TEST_LOADED_SECRET
    set -gx DOTFILES_TEST_SECRET_MODE ok
    dotfiles_load_secret DOTFILES_TEST_LOADED_SECRET "$backend" "$reference" >"$test_root/stdout"
    or fail 'successful backend lookup failed'
    test "$DOTFILES_TEST_LOADED_SECRET" = 'fixture value with spaces'; or fail 'credential changed or metadata included'
    test ! -s "$test_root/stdout"; or fail 'helper printed a credential'
    /bin/sh -c '[ "$DOTFILES_TEST_LOADED_SECRET" = "fixture value with spaces" ]'; or fail 'credential was not exported'

    set -gx DOTFILES_TEST_LOADED_SECRET inherited
    set -gx DOTFILES_TEST_SECRET_MODE fail
    dotfiles_load_secret DOTFILES_TEST_LOADED_SECRET "$backend" "$reference"; or fail 'inherited credential was not accepted'
    test "$DOTFILES_TEST_LOADED_SECRET" = inherited; or fail 'inherited credential was overwritten'

    for mode in fail empty
        set -e DOTFILES_TEST_LOADED_SECRET
        set -gx DOTFILES_TEST_SECRET_MODE "$mode"
        if dotfiles_load_secret DOTFILES_TEST_LOADED_SECRET "$backend" "$reference" >"$test_root/stdout"
            fail 'missing or failed lookup succeeded'
        end
        set -q DOTFILES_TEST_LOADED_SECRET; and fail 'failed lookup exported a value'
        test ! -s "$test_root/stdout"; or fail 'failed lookup printed a value'
    end
end

dotfiles_load_secret 'INVALID-NAME' keychain example-service
test $status -eq 2; or fail 'invalid variable name was accepted'
dotfiles_load_secret DOTFILES_TEST_LOADED_SECRET unknown example-service
test $status -eq 2; or fail 'unknown backend was accepted'

set -gx PATH "$test_root/empty"
dotfiles_load_secret DOTFILES_TEST_LOADED_SECRET keychain example-service
test $status -eq 1; or fail 'missing backend was accepted'
printf 'Fish secret loading: passed\n'
