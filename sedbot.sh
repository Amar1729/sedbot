offset=-1

while :
do
  # For each update
  # http://www.starkandwayne.com/blog/bash-for-loop-over-json-array-using-jq/
  for update in $(curl -sS -X GET "https://api.telegram.org/bot${TOKEN}/getUpdates?offset=${offset}" | jq -r '.result[] | @base64'); do
    update=$(echo ${update} | base64 --decode)
    offset=$((1+$(echo ${update} | jq -r ".update_id")))
    text=$(echo ${update} | jq -r ".message.text")
    username=$(echo ${update} | jq -r ".message.from.username")
    echo "${update}"
    echo
    if [[ "${text}" == /sed* ]] && [[ "${username}" != stream_editor_bot ]]; then
      sed_cmd="${text:5}"
      reply_to_message_text=$(echo ${update} | jq -r ".message.reply_to_message.text")
      sed_result=$(echo "${reply_to_message_text}" | sed --posix "${sed_cmd}" 2>&1)
      sed_return_code=$?

      message_text=""
      # If the command succeeded, then put @username:\n before the result.
      if [[ ${sed_return_code} -eq 0 ]]; then
        message_text="@$(echo ${update} | jq -r ".message.reply_to_message.from.username"):"
        message_text+='\n'
      fi
      message_text+="${sed_result}"

      chat_id=$(echo "$update" | jq -r ".message.chat.id")

      # Send reply.
      json="{\"chat_id\" : ${chat_id}, \"text\" : \"${message_text}\" }"

      curl -X POST -H "Content-Type: application/json" -d "${json}" "https://api.telegram.org/bot${TOKEN}/sendMessage"
      echo
      echo
    fi
  done
done
