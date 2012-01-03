Robot        = require('hubot').robot()
Adapter      = require('hubot').adapter()

HTTPS        = require 'https'
EventEmitter = require('events').EventEmitter
Yammer        = require('./node-yammer').Yammer

class YammerAdapter extends Adapter
 send: (user, strings...) ->
   strings.forEach (str) =>
     text = str
     console.log text
     yamsText = str.split('\n')
     yamsText.forEach (yamText) =>
       @bot.send(user,yamText)

 reply: (user, strings...) ->
   strings.forEach (text) =>
       @bot.reply(user,text)

 run: ->
   self = @
   options =
    key         : process.env.HUBOT_YAMMER_KEY
    secret      : process.env.HUBOT_YAMMER_SECRET
    token       : process.env.HUBOT_YAMMER_TOKEN
    tokensecret : process.env.HUBOT_YAMMER_TOKEN_SECRET
    groups      : process.env.HUBOT_YAMMER_GROUPS or "hubot" 
   bot = new YammerRealtime(options)

   bot.listen (err, data) ->
      user_name = (reference.name for reference in data.references when reference.type is "user")

      data.messages.forEach (message) =>
         message = message.body.plain
         console.log "received #{message} from #{user_name}"

         self.receive new Robot.TextMessage user_name, message
      if err
         console.log "received error: #{err}"

   @bot = bot

exports.use = (robot) ->
 new YammerAdapter robot

class YammerRealtime extends EventEmitter
 self = @
 groups_ids = []
 constructor: (options) ->
    if options.token? and options.secret? and options.key? and options.tokensecret?
      @yammer = new Yammer
         oauth_consumer_key   : options.key
         oauth_token          : options.token
         oauth_signature      : options.secret
         oauth_token_secret   : options.tokensecret

      groups_ids = @resolving_groups_ids options.groups
    else
      throw new Error("Not enough parameters provided. I need a key, a secret, a token, a secret token")

 ## Yammer API call methods    
 listen: (callback) ->
   @yammer.realtime.messages (err, data) ->
      callback err, data.data

 send: (user,yamText) ->
   ##TODO: Adapt to flood overflow
   groups_ids.forEach (group_id) =>
      params =
         body        : yamText
         group_id    : group_id
      console.log "send message in group #{params.group_id} with text #{params.body}"

      @create_message params

 ##TODO: Write the reply fonction
 reply: (user,yamText) ->
   console.log("reply")

 ## Utility methods
 create_message: (params) ->
   @yammer.createMessage params, (err, data, res) ->
      if err
         console.log "yammer send error: #{err} #{data}"

      console.log "Status #{res.statusCode}"

 resolving_groups_ids: (groups) ->
   result = []

   @yammer.groups (err, data) ->
      data.forEach (existing_group) =>
         groups.split(",").forEach (group) =>
            if group is existing_group.name then result.push(existing_group.id)

      console.log("groups list : " + groups)
      console.log("groups_ids list : " + result)

   result