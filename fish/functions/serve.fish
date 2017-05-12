function serve -v port -d "Launch a webserver serving the current directory"
  python -m SimpleHTTPServer $port
end