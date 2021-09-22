#!/bin/bash

target_filename='hosts_prod.ini'
comment_identifier="#"

empty_lines=$(grep -n "^$" $target_filename | sed 's/\([0-9]*\).*/\1/' | tr '\n' ',')
IFS=',' read -a batches <<< $empty_lines

git fetch > /dev/null 2>&1
version_tag=$(git describe --tags --abbrev=0)

for ((i=0;i<${#batches[@]};i++)) do
  start=${batches[$i]}
  end=${batches[$i+1]}

  if [ $i -eq $((${#batches[@]}-1)) ]; then
    end='$'
  fi

  # Uncomment customers block
  sed -i "$start,$end s/^$comment_identifier //g" $target_filename

  git add $target_filename && git commit -m "chore: deploy $(($i+1))/$((${#batches[@]}))"
  git push origin master

  gh release create $version_tag "$@" <<< release_prompt_answers.txt
  version_tag=$(echo $version_tag | awk -F. -v OFS=. 'NF==1{print ++$NF}; NF>1{if(length($NF+1)>length($NF))$(NF-1); $NF=sprintf("%0*d", length($NF), ($NF+1)); print}')

  # Reset comments
  sed -i "2,$ s/^dial/# dial/g" $target_filename
done

git add $target_filename && git commit -m "chore: reset deploy hosts"
git push origin master
