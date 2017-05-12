if hash jq ^ /dev/null
  function json -d "JSON Pretty Print"
    jq '.'
  end
else
  function json -d "JSON Pretty Print"
    python -m json.tool
  end
end