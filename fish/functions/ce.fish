function ce -d "docker compose exec" --wraps "docker-compose"
  set app (
    cat docker-compose.yml | \
    ruby -ryaml -rjson -e 'puts JSON.generate(YAML.load(ARGF))' | \
    jq -r '.services | to_entries[] | select(.value.build) | .key'
  )
  docker-compose run --rm --no-deps $app $argv
end