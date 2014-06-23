HOME=~ubuntu
echo "updating client $1"
GIT=$(lookup.sh cdn-7002)
test -z $GIT && exit -1
( (cd $1 && git pull) || (git clone ssh://git@bitbucket.com/redduck/$1 && cd $1 && git remote add cdn $(echo $GIT | sed -e 's/tcp/http/')/$1) ) && (cd $1 && git push cdn master) && exit 0