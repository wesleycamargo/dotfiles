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
# get-appxpackage *3dbuilder* | remove-appxpackage
get-appxpackage Microsoft.ZuneVideo | remove-appxpackage
get-appxpackage Microsoft.ZuneMusic | remove-appxpackage
get-appxpackage Microsoft.WindowsMaps | remove-appxpackage
get-appxpackage Microsoft.SkypeApp | remove-appxpackage
get-appxpackage Microsoft.MixedReality.Portal | remove-appxpackage
# get-appxpackage Microsoft.Print3D | remove-appxpackage
get-appxpackage Microsoft.MicrosoftSolitaireCollection | remove-appxpackage
get-appxpackage Microsoft.GetHelp | remove-appxpackage
get-appxpackage Microsoft.GetStarted | remove-appxpackage
