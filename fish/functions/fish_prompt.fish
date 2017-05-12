function fish_prompt
  set _status $status

  z --add "$PWD"

  echo

  set_color magenta
  printf '%s' (whoami)
  set_color normal
  printf ' at '

  set_color yellow
  printf '%s' (hostname | cut -d . -f 1 | tr '[:upper:]' '[:lower:]')
  set_color normal
  printf ' in '

  set_color $fish_color_cwd
  printf '%s' (prompt_pwd)
  set_color normal

  if begin; which git >/dev/null ^&1; and git rev-parse >/dev/null ^&1; end
    set_color normal
    printf ' on '
    set_color magenta
    printf '%s' (git symbolic-ref --short HEAD ^/dev/null; or git rev-parse --short HEAD )
    set_color green

    set index (git status --porcelain --ignore-submodules=dirty)

    if printf "%s\n" $index | grep '^??' > /dev/null ^&1
      echo -n "?"
    end

    if printf "%s\n" $index | grep '^.[MADRCU]' > /dev/null ^&1
      echo -n "!"
    end

    set_color normal
  end

  echo

  if test $_status -eq 0
    set_color white -o
    printf '$ '
  else
    set_color red -o
    printf '[%d] $ ' $_status
  end

  set_color normal
end
