function m -d "mate" --wraps "mate"
  if test -n "$SSH_CONNECTION"
    if test (count $argv) = 0
      rmate .
    else
      rmate $argv
    end
  else
    if test (count $argv) = 0
      mate .
    else
      mate $argv
    end
  end
end