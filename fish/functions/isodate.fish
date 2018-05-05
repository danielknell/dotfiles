function isodate -d "ISO 8601 date"
  python -c "import datetime; print(datetime.datetime.utcnow().isoformat(); + 'Z')"
end
