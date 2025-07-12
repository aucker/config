Invoke-Expression (&starship init powershell)

Set-PSReadLineOption -EditMode Emacs

# Set-PSReadLineOption -PredictionViewStyle ListView

# replace 'Ctrl+t' and 'Ctrl+r' with your preferred bindings:
Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r'

Set-Alias -Name vim -Value nvim
Set-Alias -Name c -Value clear
Set-Alias -Name r -Value yazi
Set-Alias -Name z -Value zoxide
# Set-Alias -Name code -Value codium

Invoke-Expression (& { (zoxide init powershell | Out-String) })
