function uuid -d "UUID"
  uuidgen | tr '[:upper:]' '[:lower:]' | tr -d '[:space:]' | pbcopy
end
