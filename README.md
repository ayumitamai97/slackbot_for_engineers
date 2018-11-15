# Usage
## Setting Environment Variables
```bash
$ vim ~/.bash_profile
```
```
# ~/.bash_profile
export SLACK_BOT_TOKEN=YOUR_TOKEN
export SLACK_BOT_CHANNEL=TARGET_CHANNEL
export SLACK_MY_USER_ID=YOUR_SLACK_USER_ID
```
```bash
$ source ~/.bash_profile
```
* `YOUR_TOKEN` should be look like this:  
`abab-123456789012-345678901234-1AbCDEf2ghi3JK345`
* `TARGET_CHANNEL` should be look like this:  
`ABCDE1FGH`
* `YOUR_SLACK_USER_ID` should be like this:  
`"<@ABCDEF12>"`  
(User ID is like `<@ABCDEF12>`, but it should be also double-quoted)

* You can get your team members' user ids including yours here:  
`https://slack.com/api/users.list?token=YOUR_TOKEN`

## Execution
### Command
```bash
$ clockwork clockwork_crawler.rb
```
If you run it in an AWS EC2 instance and so on,
```bash
$ nohup clockwork clockwork_crawker.rb &
```
### Change Execution Schedule
https://github.com/adamwiggins/clockwork#quickstart

```ruby
# clockwork_crawler.rb
every(1.day, 'notify_slack', :at => '23:00')
every(1.hour, 'notify_slack')
# and so on...
```
