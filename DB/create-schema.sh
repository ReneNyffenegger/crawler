if [ ! -d ${digitales_backup}crawler ]; then
  echo "Crawler directory not found"
  exit -1;
fi


echo "
create table domain (
  domain text not null primary key
);

create table path (
  id     integer  not null primary key autoincrement,
  domain text     not null references domain,
  path   text     not null,
  unique (domain, path)
);

create table link (
  path_from integer not null references path,
  path_to   integer not null references path
);

create table phone_number (
  phone_number text    not null,
  id_path      integer not null references path
);

.quit
" | sqlite3 "${digitales_backup}crawler/crawler.db"
