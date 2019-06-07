set -e fish_greeting

set -x DOTFILES "$HOME/.dotfiles"

set -x PATH .bin "$DOTFILES/bin" $PATH

set -x PYTHONSTARTUP "$DOTFILES/python/pythonrc"

set -x PYTHONDONTWRITEBYTECODE 1

set -x VIRTUAL_ENV_DISABLE_PROMPT 1

if [ -f $HOME/.iterm2_shell_integration.fish ]
   . $HOME/.iterm2_shell_integration.fish
end

if [ -f $HOME/.local.fish ]
	. $HOME/.local.fish
end

if [ -d /usr/local/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/bin ]
  set -x PATH $PATH /usr/local/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/bin/
end

direnv hook fish | source