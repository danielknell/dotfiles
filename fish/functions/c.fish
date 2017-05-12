function c -d "docker compose" --wraps "docker-compose"
  docker-compose $argv
end