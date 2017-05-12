# ported from https://github.com/rupa/z/blob/b620b0a8af9fa4bd476087484fd0626d16fc4358/z.sh

# maintains a jump-list of the directories you actually use
#
# INSTALL:
#   * put something like this in your config.fish:
#     source /path/to/z.sh
#   * put something like this in your fish_prompt.fish
#     z --add "$PWD"
#   * cd around for a while to build up the db
#   * PROFIT!!
#
# USE:
#   * z foo   # cd to most frecent dir matching foo
#   * z foo bar # cd to most frecent dir matching foo and bar
#   * z -r foo  # cd to highest ranked dir matching foo
#   * z -t foo  # cd to most recently accessed dir matching foo
#   * z -l foo  # list matches instead of cd
#   * z -c foo  # restrict matches to subdirs of $PWD

if [ -d "$HOME/.z" ]
  echo "ERROR: z.sh's datafile ($HOME/.z) is a directory."
end

function z -d "maintains a jump-list of the directories you actually use."
  set -l datafile "$HOME/.z"

  # add entries
  if [ "$argv[1]" = "--add" ]
    set -e argv[1]

    # $HOME isn't worth matching
    [ "$argv" = "$HOME" ]; and return

    # maintain the data file
    set -l tempfile (mktemp $datafile.XXXXXX)
    while read line
      # only count directories
      [ -d (echo $line | sed 's/|.*//') ]; and echo $line
    end < "$datafile" | awk -v path="$argv" -v now=(date +%s) -F"|" '
      BEGIN {
      rank[path] = 1
      time[path] = now
      }
      $2 >= 1 {
      # drop ranks below 1
      if( $1 == path ) {
        rank[$1] = $2 + 1
        time[$1] = now
      } else {
        rank[$1] = $2
        time[$1] = $3
      }
      count += $2
      }
      END {
      if( count > 9000 ) {
        # aging
        for( x in rank ) print x "|" 0.99*rank[x] "|" time[x]
      } else for( x in rank ) print x "|" rank[x] "|" time[x]
      }
    ' ^/dev/null > "$tempfile"
    # do our best to avoid clobbering the datafile in a race condition
    if [ $status -ne 0 -a -f "$datafile" ]
      env rm -f "$tempfile"
    else
      env mv -f "$tempfile" "$datafile"; or env rm -f "$tempfile"
    end

  # tab completion
  else if [ "$argv[1]" = "--complete" -a -s "$datafile" ]
  set -e argv[1]
  
  while read line
    [ -d (echo $line | sed 's/|.*//') ]; and echo $line
  end < "$datafile" | awk -v q="$argv[1]" -F"|" '
    BEGIN {
    if( q == tolower(q) ) imatch = 1
    q = substr(q, 3)
    gsub(" ", ".*", q)
    }
    {
    if( imatch ) {
      if( tolower($1) ~ tolower(q) ) print $1
    } else if( $1 ~ q ) print $1
    }
  ' ^/dev/null
  else
  # list/go
  set -l last ''
  set -l list 0
  set -l typ ''
  set -l fnd ''
  
  while [ (count $argv) -gt 0 ]
    switch "$argv[1]"
    case '--'
    while [ "$1" ]; do 
      set -e argv[1]
      set fnd "$fnd $argv[1]"
    end
    case '-*'
    set -l opt (echo "$argv[1]" | awk '{print substr($0, 2)}') 
    while [ ! -z "$opt" ] 
      switch (echo "$opt" | awk '{print substr($0, 1, 1)}')
      case "c"
      set fnd "^$PWD $fnd"
      case "h" 
      echo "z [-chlrtx] args" >&2
      return
      case "x"
      sed -i -e "\:^$PWD|.*:d" "$datafile"
      case "l" 
      set list 1
      case "r" 
      set typ "rank"
      case "t" 
      set typ "recent"
      end
      set opt (echo "$opt" | awk '{print substr($0, 2)}') 
    end
    case "*"
     set fnd $fnd $argv[1]
    end; 
    set last $argv[1]
    set -e argv[1]
  end
  
  set -e fnd[1]
  
  echo "$fnd"
  
  [ "$fnd" -a "$fnd" != "^$PWD " ]; or set list 1

  # if we hit enter on a completion just go there
  switch "$last"
  # completions will always start with /
  case "/*"
    [ -z "$list" -a -d "$last" ]; and cd "$last"; and return
  end

  # no file yet
  [ -f "$datafile" ]; or return

  set -l cd (
    while read line
    [ -d (echo $line | sed 's/|.*//') ]; and echo $line
    end < "$datafile" | awk -v t=(date +%s) -v list="$list" -v typ="$typ" -v q="$fnd" -F"|" '
    function frecent(rank, time) {
    # relate frequency and time
    dx = t - time
    if( dx < 3600 ) return rank * 4
    if( dx < 86400 ) return rank * 2
    if( dx < 604800 ) return rank / 2
    return rank / 4
    }
    function output(files, out, common) {
    # list or return the desired directory
    if( list ) {
      cmd = "sort -n >&2"
      for( x in files ) {
      if( files[x] ) printf "%-10s %s\n", files[x], x | cmd
      }
      if( common ) {
      printf "%-10s %s\n", "common:", common > "/dev/stderr"
      }
    } else {
      if( common ) out = common
      print out
    }
    }
    function common(matches) {
    # find the common root of a list of matches, if it exists
    for( x in matches ) {
      if( matches[x] && (!short || length(x) < length(short)) ) {
      short = x
      }
    }
    if( short == "/" ) return
    # use a copy to escape special characters, as we want to return
    # the original. yeah, this escaping is awful.
    clean_short = short
    gsub(/[\(\)\[\]\|]/, "\\\\&", clean_short)
    for( x in matches ) if( matches[x] && x !~ clean_short ) return
    return short
    }
    BEGIN {
    gsub(" ", ".*", q)
    hi_rank = ihi_rank = -9999999999
    }
    {
    if( typ == "rank" ) {
      rank = $2
    } else if( typ == "recent" ) {
      rank = $3 - t
    } else rank = frecent($2, $3)
    if( $1 ~ q ) {
      matches[$1] = rank
    } else if( tolower($1) ~ tolower(q) ) imatches[$1] = rank
    if( matches[$1] && matches[$1] > hi_rank ) {
      best_match = $1
      hi_rank = matches[$1]
    } else if( imatches[$1] && imatches[$1] > ihi_rank ) {
      ibest_match = $1
      ihi_rank = imatches[$1]
    }
    }
    END {
    # prefer case sensitive
    if( best_match ) {
      output(matches, best_match, common(matches))
    } else if( ibest_match ) {
      output(imatches, ibest_match, common(imatches))
    }
    }
  ')
  [ $status -gt 0 ]; and return
  [ "$cd" ]; and cd "$cd"
  end
end