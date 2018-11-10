module Slack
  def post_message(text)
    Net::HTTP.post_form(
      URI.parse('https://slack.com/api/chat.postMessage'),
      {
        "token" => ENV["SLACK_BOT_TOKEN"],
        "channel"=> ENV["SLACK_BOT_CHANNEL"],
        "text"=> text
      })
  end
end
