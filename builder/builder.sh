# This should only be run on the build machine, NOT the dev machine, it will break the local changes!
git fetch --all
git reset --hard origin/master
releases=($(ls releases/ArchLinuxARM-*))
if [[ "${#releases[@]}" -gt 8 ]]; then # Only keep 8
  rm -f ${releases[@]::((${#releases[@]}-8))}
fi
. build.sh