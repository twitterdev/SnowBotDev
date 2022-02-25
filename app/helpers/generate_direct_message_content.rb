#Generates all content for bot Direct Messages.
#Many responses include configuration metadata/resources, such as photos, links, and location list.
#These metadata are loading from local files.
#Direct Messages with media require a side call to Twitter upload endpoint, so this class uses a Twitter API object. 

require_relative 'twitter_api'          #Hooks to Twitter Public APIs via 'twitter' gem. 
require_relative 'third_party_request'  #Hooks to third-party APIs.
require_relative 'get_resources'        #Loads local resources used to present DM menu options and photos to users.

class GenerateDirectMessageContent
	
	VERSION = 2.88
	BOT_NAME = '@SnowBotDev'
	BOT_CHAR = '❄'
  GET_STARTED_MESSAGE = "Send 'main' for main menu and 'help' for a list of supported commands. \n To get straight to the snow reports, send 'reports'"

	attr_accessor :twitter_client,
		            :resources,
		            :thirdparty_api

	def initialize(setup=nil) #'Setup Welcome Message' script using this too, but does not require many helper objects.

		if setup.nil?
			@twitter_client = TwitterAPI.new
			@resources = GetResources.new
			@thirdparty_api = ThirdPartyRequest.new
		end

		#puts "Created GenerateDirectMessageContent object."

	end

	#================================================================

  def generate_conversational_message(recipient_id, message)

    message_text = "#{BOT_CHAR} #{message}"

    #+ "Weather data are provided with an API from Weather Underground.\n"

    #Build DM content.
    event = {}
    event['event'] = message_create_header(recipient_id)

    message_data = {}
    message_data['text'] = message_text

    message_data['quick_reply'] = {}
    message_data['quick_reply']['type'] = 'options'

    options = build_home_option

    message_data['quick_reply']['options'] = options

    event['event']['message_create']['message_data'] = message_data
    event.to_json

  end

  def generate_tweet(recipient_id)

		#Build DM content.
		event = {}
		event['event'] = message_create_header(recipient_id)

		#Read database and get list of Tweet IDs
		top_tweet_ids = @resources.get_top_tweet_ids
		top_tweet = "https://twitter.com/user/status/#{top_tweet_ids[0]}"

		message_data = {}
		message_data['text'] = top_tweet

    options = []
    options += build_home_option

    message_data['quick_reply'] = {}
    message_data['quick_reply']['type'] = 'options'
    message_data['quick_reply']['options'] = options
    event['event']['message_create']['message_data'] = message_data

    event.to_json

	end

	def generate_random_photo(recipient_id)

		#Build DM content.
		event = {}
		event['event'] = message_create_header(recipient_id)
		
		message_data = {}
		
		#Select photo(at random).
		photo = @resources.photos_list.sample
    puts photo
		message = "#{photo[1]}"
		
		#Confirm photo file exists
		photo_file = "#{@resources.photos_home}/photos/#{photo[0]}"
		puts photo_file
		
		if File.file? photo_file
			media_id = @twitter_client.get_media_id(photo_file)

			attachment = {}
			attachment['type'] = "media"
			attachment['media'] = {}
			attachment['media']['id'] = media_id

			message_data['attachment'] = attachment

		else
			message = "Sorry, could not load photo: #{photo_file}."
    end

    message_data['text'] = message

		message_data['quick_reply'] = {}
		message_data['quick_reply']['type'] = 'options'

		options = []
		options = build_photo_option
		options += build_home_option('with_description')

		message_data['quick_reply']['options'] = options
		
		event['event']['message_create']['message_data'] = message_data

		event.to_json

	end

  def generate_playlist_list(recipient_id)

	  event = {}
	  event['event'] = message_create_header(recipient_id)

	  message_data = {}
	  message_data['text'] = 'Select a playlist:'

	  message_data['quick_reply'] = {}
	  message_data['quick_reply']['type'] = 'options'

	  options = []

	  @resources.playlists_list.each do |item|
		  if item.count > 0
			  option = {}
			  option['label'] = "#{BOT_CHAR} " + item[0]
			  option['metadata'] = "playlist_choice: #{item[0]}"
			  option['description'] = item[1]
			  options << option
		  end
	  end

	  options += build_home_option('with description')

	  message_data['quick_reply']['options'] = options

	  event['event']['message_create']['message_data'] = message_data
	  event.to_json

  end
  
  def generate_playlist(recipient_id, playlist_choice)

	  #Build link response.
	  message = "Issue with sharing #{playlist_choice} playlist..."
	  @resources.playlists_list.each do |playlist|
		  if playlist[0] == playlist_choice
			  message = playlist[2]
			  break
		  end
	  end

	  event = {}
	  event['event'] = message_create_header(recipient_id)

	  message_data = {}
	  message_data['text'] = message

	  message_data['quick_reply'] = {}
	  message_data['quick_reply']['type'] = 'options'

	  options = build_back_option 'playlists'
	  options += build_home_option

	  message_data['quick_reply']['options'] = options
	  event['event']['message_create']['message_data'] = message_data
	  event.to_json
  end

  def generate_link_list(recipient_id)

		event = {}
		event['event'] = message_create_header(recipient_id)

		message_data = {}
		message_data['text'] = 'Select a link:'

		message_data['quick_reply'] = {}
		message_data['quick_reply']['type'] = 'options'

		options = []
		
		@resources.links_list.each do |item|
			if item.count > 0 
				option = {}
				option['label'] = "#{BOT_CHAR} " + item[0]
				option['metadata'] = "link_choice: #{item[0]}"
				option['description'] = item[1]
				options << option
			end
		end
		
		options += build_home_option('with description')

		message_data['quick_reply']['options'] = options

		event['event']['message_create']['message_data'] = message_data
		event.to_json

	end

  def generate_link(recipient_id, link_choice)

		#Build link response.
		message = "Issue with displaying #{link_choice}..."
		@resources.links_list.each do |link|
			if link[0] == link_choice
				message = "#{link[2]}\nSummary:\n#{link[3]}"
				break
			end
		end
		event = {}
	  event['event'] = message_create_header(recipient_id)

	  #message_data = "#{BOT_CHAR} ⇨ Learn about snow \n  send: 'learn', 'link' \n " +
	  message_data = {}
		message_data['text'] = message

	  message_data['quick_reply'] = {}
	  message_data['quick_reply']['type'] = 'options'

		options = build_back_option 'links'
	  options += build_home_option

	  message_data['quick_reply']['options'] = options
	  event['event']['message_create']['message_data'] = message_data
	  event.to_json
		
  end

	#Saved for when we have a workaround for getting user location coordinates.
  def generate_weather_info(recipient_id, coordinates)

	  weather_info = @thirdparty_api.get_current_weather(coordinates[1], coordinates[0])

	  event = {}
	  event['event'] = message_create_header(recipient_id)

	  message_data = {}
	  message_data['text'] = weather_info

	  message_data['quick_reply'] = {}
	  message_data['quick_reply']['type'] = 'options'
	  
	  options = []
	  
	  options += build_home_option

	  message_data['quick_reply']['options'] = options
	  
	  event['event']['message_create']['message_data'] = message_data
	  event.to_json

  end

	#Pass in 'region', and serve up sub menu.
  #Generates Quick Reply for presenting user a Location List via Direct Message.
	#https://dev.twitter.com/rest/direct-messages/quick-replies/options
	def generate_location_list(recipient_id, region)

		event = {}
		event['event'] = message_create_header(recipient_id)

		message_data = {}
		if region == 'top'
		  message_data['text'] = "#{BOT_CHAR} Select your region of interest:"
		else
			message_data['text'] = "#{BOT_CHAR} Select your area of interest:"
		end

		message_data['quick_reply'] = {}
		message_data['quick_reply']['type'] = 'options'

		options = []

    #puts "building back button with region: #{region}"
    if region != 'top'
      options += build_back_option 'top'
    else
      options += build_back_option 'main'
    end

		@resources.locations_list.each do |item|

			option = {}

      if item[0].downcase == region.downcase

        if item.length == 2 #We are serving up a sub menu
          option = {}
          option['label'] = "#{BOT_CHAR} " + item[1]
          option['metadata'] = "region_choice: #{item[1].strip}"
          #option['description'] = 'what is there to say here?'
        else  #We are serving up a resort selection
          option = {}
          option['label'] = "#{BOT_CHAR} " + item[1]
          option['metadata'] = "location_choice: #{item[1].strip}|#{region}"
          #option['description'] = 'what is there to say here?'
        end

				#puts "adding option: #{option}"
        options << option
			end
		end

		options += build_home_option

		message_data['quick_reply']['options'] = options

		event['event']['message_create']['message_data'] = message_data

		event.to_json

	end

  #V2: Main change is when and where to call this, e.g. not always from level 1 as with V1.
  # 'top' is passed in when coming from the top menu in order to handle the 'back' button properly....
  def generate_location_info(recipient_id, location_name, region)

	  resort_id = 0

	  @resources.locations_list.each do |item|

			if item[1].strip == location_name.strip

				resort_id = item[4].strip
				break
		  end  
	  end

		resort_info = @thirdparty_api.get_resort_info(resort_id)

	  event = {}
	  event['event'] = message_create_header(recipient_id)

	  message_data = {}
	  message_data['text'] = resort_info

	  message_data['quick_reply'] = {}
	  message_data['quick_reply']['type'] = 'options'

		#puts "building back button with region: #{region}"
    options = build_back_option region

    options = options + build_home_option  #('with_description')

	  message_data['quick_reply']['options'] = options
	  event['event']['message_create']['message_data'] = message_data
	  event.to_json

  end

	#=====================================================================================
	
	def generate_greeting

		greeting = "#{BOT_CHAR} Welcome to #{BOT_NAME} (ver. #{VERSION}) #{BOT_CHAR}. #{GET_STARTED_MESSAGE}."
		greeting

	end

	def generate_main_message
		greeting = ''
		greeting = generate_greeting
		greeting =+ "#{BOT_CHAR} Thanks for stopping by... #{BOT_CHAR}"
		greeting

	end

	def message_create_header(recipient_id)

		header = {}

		header['type'] = 'message_create'
		header['message_create'] = {}
		header['message_create']['target'] = {}
		header['message_create']['target']['recipient_id'] = "#{recipient_id}"

		header

	end

	def generate_welcome_message_default

		message = {}
		message['welcome_message'] = {}
		message['welcome_message']['message_data'] = {}
		message['welcome_message']['message_data']['text'] = generate_greeting

		message['welcome_message']['message_data']['quick_reply'] = generate_welcome_options

		message.to_json

	end

	#Users are shown this when returning home... A way to 're-start' dialogs...
	#https://dev.twitter.com/rest/reference/post/direct_messages/welcome_messages/new
	def generate_welcome_message(recipient_id)

		#puts "In generate welcome message"
		
		event = {}
		event['event'] = message_create_header(recipient_id)

		message_data = {}
		message_data['text'] = "#{BOT_CHAR} Hi again...\n\n#{GET_STARTED_MESSAGE}." #generate_main_message

		message_data['quick_reply'] = generate_welcome_options

		event['event']['message_create']['message_data'] = message_data

		event.to_json

	end
 
  def generate_system_info(recipient_id)

	  message_text = "#{BOT_CHAR} This is a snow bot (version #{VERSION})... \n " +
		               "A demo based on the Twitter Account Activity and Direct Messasge APIs.    \n" +
				            "\n" +
				            "See here for project code and tutorial: https://github.com/twitterdev/SnowBotDev/wiki. \n" +
	                 "\n" + 
	                 "Credits: \n" + 
	                 "Snow reports are provided with an API from @SnoCountryCom.\n"

		#+ "Weather data are provided with an API from Weather Underground.\n"
	  

	  #Build DM content.
	  event = {}
	  event['event'] = message_create_header(recipient_id)

	  message_data = {}
	  message_data['text'] = message_text

	  message_data['quick_reply'] = {}
	  message_data['quick_reply']['type'] = 'options'

	  options = build_home_option

	  message_data['quick_reply']['options'] = options

	  event['event']['message_create']['message_data'] = message_data
	  event.to_json
  end

  def generate_system_help(recipient_id)

	  message_text = "Several commands are supported: \n \n" + 
                "#{BOT_CHAR} ⇨ Main menu \n  send: 'main', 'home', 'bot' \n " +
                "#{BOT_CHAR} ⇨ See photo \n  send: 'photo', 'pic' \n  " +
		            "#{BOT_CHAR} ⇨ Get resort snow report \n  send: 'report(s)', 'resort(s)' \n    via http://feeds.snocountry.net/conditions \n "  +
				        "#{BOT_CHAR} ⇨ Learn about snow \n  send: 'learn', 'link' \n " +
	              "#{BOT_CHAR} ⇨ Get playlist \n  send: 'playlist', 'music' \n " +
				        "#{BOT_CHAR} ⇨ See snow Tweet of the day \n  send: 'Tweet', 'TOD' \n " +
	              "#{BOT_CHAR} ⇨ Learn about the #{BOT_NAME} \n   send: 'about' \n " +
	              "#{BOT_CHAR} ⇨ Review these commands \n  send: 'help' \n "

	  #Build DM content.
	  event = {}
	  event['event'] = message_create_header(recipient_id)

	  message_data = {}
	  message_data['text'] = message_text

	  message_data['quick_reply'] = {}
	  message_data['quick_reply']['type'] = 'options'

	  options = []
	  #Not including 'description' option attributes.

	  options = build_home_option

	  message_data['quick_reply']['options'] = options

	  event['event']['message_create']['message_data'] = message_data
	  event.to_json
  end
	
	#=====================================================================================

	def build_custom_options

		options = []

		option = {}
		option['label'] = "#{BOT_CHAR} Request snow report"
		option['description'] = 'SnoCountry reports for select areas.'
		option['metadata'] = 'snow_report'
		options << option

    option = {}
    option['label'] = "#{BOT_CHAR} See snow picture 📷 "
    option['description'] = 'Check out a random snow related photo...'
    option['metadata'] = 'see_photo'
    options << option

		option = {}
		option['label'] = "#{BOT_CHAR} Learn something new about snow"
		option['description'] = 'Other than it is fun to slide on...'
		option['metadata'] = 'learn_snow'
		options << option

		option = {}
		option['label'] = "#{BOT_CHAR} Get geo, weather themed playlist"
		option['description'] = 'Carefully curated Spotify playlists...'
		option['metadata'] = 'snow_music'
		options << option

		option = {}
		option['label'] = "#{BOT_CHAR} See (deep) snow Tweet of the day"
		option['description'] = 'Most engaged Tweet from last 24 hours.'
		option['metadata'] = 'snow_tweet'
		options << option

		options

	end

	def build_default_options

		options = []

		option = {}
		option['label'] = '❓ Learn more about this system'
		option['description'] = 'Including a link to underlying code...'
		option['metadata'] = 'learn_more'
		options << option

		option = {}
		option['label'] = '☔ Help'
		option['description'] = 'Help with system commands'
		option['metadata'] = 'help'
		options << option

		option = {}
		option['label'] = '⌂ Home'
		option['description'] = 'Go back home'
		option['metadata'] = "return_home"
		options << option

		options

	end

  def build_photo_option

	  options = []

	  option = {}
	  option['label'] = "#{BOT_CHAR} Another 📷 "
	  option['description'] = 'Another snow photo'
	  option['metadata'] = "see_photo"
	  options << option

	  options

  end
  
  #Types: list choices, going back to list. links, resorts
	def build_back_option(type=nil, description=nil)

		#type: locations_top, locations_sub
		#puts "Building 'back' button with type: #{type} with #{description}"

		options = []

		option = {}
		option['label'] = '⬅ Back'
		option['description'] = 'Previous list...' if description
		option['metadata'] = "go_back #{type} "

		options << option

		options
		
  end
  
	def build_home_option(description=nil)
		
		options = []

		option = {}
		option['label'] = '⌂ Home'
		option['description'] = 'Go back home' if description
		option['metadata'] = "return_home"
		options << option

		options

	end

	def generate_welcome_options
		quick_reply = {}
		quick_reply['type'] = 'options'
		quick_reply['options'] = []

		custom_options = []
		custom_options = build_custom_options
		custom_options.each do |option|
			quick_reply['options'] << option
		end

		default_options = []
		default_options = build_default_options
		default_options.each do |option|
			quick_reply['options'] << option
		end

		quick_reply
	end

  #=============================================================

	#https://dev.twitter.com/rest/reference/post/direct_messages/welcome_messages/new
	def generate_system_maintenance_welcome

		message = {}
		message['welcome_message'] = {}
		message['welcome_message']['message_data'] = {}
		message['welcome_message']['message_data']['text'] = "System going under maintenance... Come back soon..."

		message.to_json

	end

	#https://dev.twitter.com/rest/reference/post/direct_messages/welcome_messages/new
	def generate_message(recipient_id, message)

		#Build DM content.
		event = {}
		event['event'] = message_create_header(recipient_id)

		message_data = {}
		message_data['text'] = message

		event['event']['message_create']['message_data'] = message_data

		#TODO: Add home option? options = options + build_home_option

		event.to_json
	end

end

#Testing
if __FILE__ == $0 #This script code is executed when running this file.

  generator = GenerateDirectMessageContent.new

  recipient_id = '17200003'
	@twitter_gem = TwitterAPI.new
  user_name = @twitter_gem.get_user_handle(recipient_id)
  print "Hi #{user_name}"

  region = 'top'
  link_choice = 'Snowmelt Modeling'

	json = generator.generate_link_list(recipient_id)
  print json

	json = generator.generate_link(recipient_id, link_choice)
  print json

	json = generator.generate_location_list(recipient_id, region)
  print json

end
