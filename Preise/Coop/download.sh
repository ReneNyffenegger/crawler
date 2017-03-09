# 1. Get front page

  wget                                https://www.coopathome.ch/ -nc -O $digitales_backup/crawler/Preise/Coop/wgetted/main.html
# wget --header='Accept-Language: en' https://www.coopathome.ch/ -nc -O $digitales_backup/crawler/Preise/Coop/wgetted/main_en.html

dos2unix  $digitales_backup/crawler/Preise/Coop/wgetted/main.html
