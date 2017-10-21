git config --global user.name  root
git config --global user.email root@pc

git config --unset-all credential.helper
git config --global --unset-all credential.helper
::git config --system --unset-all credential.helper

::git config --global credential.helper wincred
::git config --global credential.helper store
::git config --global credential.helper cache
::git config credential.helper "cache --timeout=20"
pause
