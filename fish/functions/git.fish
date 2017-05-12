if which hub >/dev/null ^&1
  function git -d "git" --wraps "hub"
    command hub $argv
  end
else
  function git -d "git" --wraps "git"
    command git $argv
  end
end