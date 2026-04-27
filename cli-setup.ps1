$cliTools = "https://raw.githubusercontent.com/wesleycamargo/dotfiles/refs/heads/master/cli-tools.ps1"
Invoke-Expression ((new-object net.webclient).DownloadString($cliTools))

$url = "https://raw.githubusercontent.com/wesleycamargo/dotfiles/refs/heads/master/terminal-setup.ps1"
Invoke-Expression ((new-object net.webclient).DownloadString($url))

