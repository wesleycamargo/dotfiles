# Oh My Posh Configuration
oh-my-posh --init --shell pwsh --config https://gist.githubusercontent.com/wesleycamargo/06b58b472fe0cded2e6d6451ea0778bd/raw/1c952297121a50826ef6f849bb7ee8c11d8e09a6/oh-my-posh-az-cli-az-pwsh.json | Invoke-Expression

if (Get-Module -ListAvailable -Name Terminal-Icons) {
    Import-Module Terminal-Icons
}