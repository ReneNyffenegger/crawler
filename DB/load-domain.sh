
for d in /home/rene/github/github//wordlists.ch/data/second-level-domains/* ; do
  
  if [ ! $(basename $d) == "README.md" ]; then
    echo $d
    sqlite3 ${digitales_backup}crawler/crawler.db ".import $d domain"
  fi

done
