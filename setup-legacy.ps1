Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

#Basic
choco install visualstudiocode -y
choco install azure-cli -y

# Tools Configuration
choco install git -y
git config --global alias.lg "log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit"


choco install googlechrome -y
#Dev Tools

choco install gitextensions -y

## uncomment following lines to change VS Version
#choco install visualstudio2019professional -y
choco install visualstudio2019enterprise -y
choco install sql-server-management-studio -y

choco install nodejs.install -y
choco install docker-desktop -y
choco install docker-kitematic -y


choco install azure-data-studio -y
choco install fiddler4 -y

#Work tools
choco install microsoft-teams -y
choco install screenpresso -y
choco install powerbi -y
choco install zoomit -y

#Personal Stuff
choco install spotify -y
choco install winrar -y


#Environment Stuff

dism /online /get-features | more 

Dism /online /enable-feature /featurename:NetFx3 /All /Source:D:\sources\sxs /LimitAccess
Dism /online /enable-feature /featurename:IIS-ASPNET /All /Source:D:\sources\sxs /LimitAccess
Dism /online /enable-feature /featurename:IIS-ASPNET45 /All /Source:D:\sources\sxs /LimitAccess
Dism /online /enable-feature /featurename:IIS-BasicAuthentication /All /Source:D:\sources\sxs /LimitAccess
Dism /online /enable-feature /featurename:IIS-WindowsAuthentication /All /Source:D:\sources\sxs /LimitAccess
Dism /online /enable-feature /featurename:Containers /All /Source:D:\sources\sxs /LimitAccess
Dism /online /enable-feature /featurename:Microsoft-Hyper-V-All /All /Source:D:\sources\sxs /LimitAccess

# Install azure extension
az extension add --name azure-devops

#Remove windows 10 Apps
get-appxpackage *zunemusic* | remove-appxpackage
get-appxpackage *zune* | remove-appxpackage
get-appxpackage *bingfinance* | remove-appxpackage
get-appxpackage *bingsports* | remove-appxpackage
get-appxpackage *bing* | remove-appxpackage
#get-appxpackage *xbox* | remove-appxpackage
get-appxpackage *solitaire* | remove-appxpackage
get-appxpackage *officehub* | remove-appxpackage
get-appxpackage *skypeapp* | remove-appxpackage
get-appxpackage *getstarted* | remove-appxpackage
get-appxpackage *3dbuilder* | remove-appxpackage
get-appxpackage Microsoft.ZuneVideo | remove-appxpackage
get-appxpackage Microsoft.ZuneMusic | remove-appxpackage
get-appxpackage Microsoft.WindowsMaps | remove-appxpackage
get-appxpackage Microsoft.SkypeApp | remove-appxpackage
get-appxpackage Microsoft.MixedReality.Portal | remove-appxpackage
get-appxpackage Microsoft.Print3D | remove-appxpackage
get-appxpackage Microsoft.MicrosoftSolitaireCollection | remove-appxpackage
get-appxpackage Microsoft.GetHelp | remove-appxpackage
get-appxpackage Microsoft.GetStarted | remove-appxpackage
