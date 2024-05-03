#!/bin/bash

safe_clone () {
  # $1 = Repo URL
  # $2 = Repo Dir
  # $3 = Name

  echo "Safe cloning $3"
  n=0
  until [ $n -ge 5 ]
  do
      git clone $1 $2 && break
      echo "Safe clone attempt $n fail. Retrying."
      n=$[$n+1]
      sleep 5
  done
  if ! [ -d $2 ]; 
  then
  echo "Safe clone failed for $3! Exit 35."
  exit 35
  fi
}

clone_or_pull () {
  # $1 = Repo URL
  # $2 = Repo Dir
  # $3 = Name

  echo "Cloning/Updating $3, which is cloned into $2."
  if ! [ -d $2 ];
  then
  echo "Cloning $3. $3 was not cloned before."
  safe_clone $1 $2 $3
  echo "$3 cloned successfully."
else
  echo "Pulling changes of $3. $3 was cloned before."
  cd $2
  if git pull | grep "divergent";
  then
  echo "Re-cloning $3. Force-push occured at remote $1."
  cd ..
  rm -rf $2
  safe_clone $1 $2 $3
  cd $2
  fi
  cd ..
  echo "Pulled remote changes for $3."
fi
}

checkout_latest_tag() {
  # $1 = Repo Dir
  # $2 = Name

  cd $1
  echo "Checking out latest tag for $2"
  echo "Safe fetching $2 tags"
  n=0
  until [ $n -ge 5 ]
  do
      git fetch --tags && break
      echo "Safe fetch attempt $n fail. Retrying."
      n=$[$n+1]
      sleep 5
  done
  if [ $n -ge 5 ]; 
  then
  echo "Safe fetch failed for $2! Exit 35."
  exit 35
  fi
  
  latestTag=$(git describe --tags "$(git rev-list --tags --max-count=1)")
  git checkout $latestTag

  cd ..
}