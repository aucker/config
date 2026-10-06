function fish_user_key_bindings
    if command -q fzf
        fzf --fish | source
    end
    bind \cr fzf_history
    bind \cz 'fg>/dev/null ^/dev/null'
end
