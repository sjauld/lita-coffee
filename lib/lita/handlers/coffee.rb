module Lita
  module Handlers
    class Coffee < Handler
      # TODO: money - probably in a separate handler and maybe it already exists??

      # Dependencies
      require 'json'

      # Configuration
      # redis_prefix - use a custom prefix in case something happens to clash with the redis naming
      # default_group - the name of the default group in which users will order a coffee
      # default_coffee - the coffee we will order if users don't specify what they would like
      config :redis_prefix, type: String, default: 'lita-coffee'
      config :default_group, type: String, default: 'coffee-lovers'
      config :default_coffee, type: String, default: 'Single origin espresso'
      on :loaded, :set_constants

      def set_constants(payload)
        @@REDIS_PREFIX   = config.redis_prefix
        @@DEFAULT_GROUP   = config.default_group
        @@DEFAULT_COFFEE  = config.default_coffee
      end

      route(
        /^\(coffee\)(\s+\-[bcdgist]?|\s+\+)?(.*)/i,
        :coffee,
        help: {
          '(coffee)'                      => "List the (coffee) orders for your group",
          '(coffee) -i'                   => "Display your (coffee) profile",
          '(coffee) -s Colombian Filter'  => "Set your (coffee) preference",
          '(coffee) -g Cool Kids'         => "Change your (coffee) group",
          '(coffee) +'                    => "Order a (coffee)",
          '(coffee) -c'                   => "Cancel your (coffee) order",
          '(coffee) -b You owe me one!'   => "Buy (coffee) for your group, clear the orders and send a message",
          '(coffee) -t'                   => "Display (coffee) system settings",
          '(coffee) -d'                   => "Delete you from the (coffee) system",
        }
      )

      def coffee(response)
        get_settings    = response.matches[0][0].strip == "-i"  rescue false
        set_coffee      = response.matches[0][0].strip == "-s"  rescue false
        change_group    = response.matches[0][0].strip == "-g"  rescue false
        order           = response.matches[0][0].strip == "+"   rescue false
        cancel          = response.matches[0][0].strip == "-c"  rescue false
        buy_coffee      = response.matches[0][0].strip == "-b"  rescue false
        system_settings = response.matches[0][0].strip == "-t"  rescue false
        delete_me       = response.matches[0][0].strip == "-d"  rescue false

        preference      = response.matches[0][1].strip          rescue nil

        my_user = response.user.name
        group = get_group(my_user)

        # Setup new users
        response.reply("Welcome to (coffee)! You have been setup in the #{@DEFAULT_GROUP} group with an order of #{@DEFAULT_COFFEE}. Type help (coffee) for help.") if initialize_user_redis(my_user) == :new_user

        # Retrieve my preference
        if get_settings
          settings = get_settings(my_user)
          response.reply("Your current (coffee) is #{settings[:coffee]}. You are in the #{settings[:group]} group.")
        # Set my coffee
        elsif set_coffee
          result = set_coffee(my_user,preference)
          if result == "OK"
            response.reply("(coffee) set to #{preference}")
          else
            response.reply("(sadpanda) Failed to set your (coffee) for some reason: #{result.inspect}")
          end
        # Delete me altogether
        elsif delete_me
          result = delete_user(my_user)
          if result == "OK"
            response.reply("You have been deleted from (coffee)")
          else
            response.reply("(sadpanda) Failed to delete you from (coffee) for some reason: #{result.inspect}")
          end
        # Change my coffee group
        elsif change_group
          result = set_coffee_group(my_user,preference)
          if result == "OK"
            response.reply("(coffee) group set to #{preference}")
          else
            response.reply("(sadpanda) Failed to set your (coffee) group for some reason: #{result.inspect}")
          end
        # Order a coffee
        elsif order
          result = order_coffee(my_user)
          if result == "OK"
            response.reply("Ordered you a (coffee)")
          else
            response.reply("(sadpanda) Failed to order your (coffee) for some reason: #{result.inspect}")
          end
        # Cancel a coffee
        elsif cancel
          result = cancel_coffee(my_user)
          if result == "OK"
            response.reply("Cancelled your (coffee)")
          else
            response.reply("(sadpanda) Failed to cancel your (coffee) for some reason: #{result.inspect}")
          end
        # Buy the coffees and clear the orders
        elsif buy_coffee
          response.reply("Thanks for ordering the (coffee) for #{group}!\n--")
          get_orders(group).each do |order|
            response.reply("#{order}: #{get_coffee(order)}")
            send_coffee_message(order,my_user,preference) unless order == my_user
          end
          result = clear_orders(group)
          if result == "OK"
            response.reply("Cleared all (coffee) orders for #{group}")
          else
            response.reply("(sadpanda) Failed to clear the (coffee) orders for some reason: #{result.inspect}")
          end
        # tests
        elsif system_settings
          response.reply("Redis prefix: #{@@REDIS_PREFIX}, Default coffee: #{@@DEFAULT_COFFEE}, Default group: #{@@DEFAULT_GROUP}")
        # List the orders
        else
          response.reply("Current (coffee) orders for #{group}:-\n--")
          get_orders(group).each do |order|
            response.reply("#{order}: #{get_coffee_preference(order)}")
          end
        end

      end

      #######
      private
      #######

      def initialize_user_redis(user)
        if Lita.redis.get("#{@@REDIS_PREFIX}-settings-#{user}").nil?
          Lita.redis.set("#{@@REDIS_PREFIX}-settings-#{user}",{group: @@DEFAULT_GROUP, coffee: @@DEFAULT_COFFEE})
          return :new_user
        else
          return :existing_user
        end
      end

      def delete_user(user)
        Lita.redis.delete("#{@@REDIS_PREFIX}-settings-#{user}")
      end

      def get_settings(user)
        JSON.parse(Lita.redis.get("#{@@REDIS_PREFIX}-settings-#{user}")) rescue {group: @@DEFAULT_GROUP, coffee: @@DEFAULT_COFFEE}
      end

      def get_orders(group)
        JSON.parse(Lita.redis.get("#{@@REDIS_PREFIX}-#{group}-orders")) rescue []
      end

      def get_coffee(user)
        JSON.parse(Lita.redis.get("#{@@REDIS_PREFIX}-settings-#{user}"))[:coffee] rescue @@DEFAULT_COFFEE
      end

      def get_group(user)
        JSON.parse(Lita.redis.get("#{@@REDIS_PREFIX}-settings-#{user}"))[:group] rescue @@DEFAULT_GROUP
      end

      def set_coffee(user,coffee)
        my_settings = get_settings(user)
        my_settings[:coffee] = coffee
        Lita.redis.set("#{@@REDIS_PREFIX}-settings-#{user}",my_settings)
      end

      def set_coffee_group(user,group)
        my_settings = get_settings(user)
        my_settings[:group] = group
        Lita.redis.set("#{@@REDIS_PREFIX}-settings-#{user}",my_settings)
      end

      def order_coffee(user)
        group = get_group(user)
        orders = get_orders(group)
        orders << user
        orders.uniq!
        Lita.redis.set("#{@@REDIS_PREFIX}-#{group}-orders",orders)
      end

      def cancel_coffee(user)
        group = get_group(user)
        orders = get_orders(group)
        orders.delete(user)
        Lita.redis.set("#{@@REDIS_PREFIX}-#{group}-orders",orders)
      end

      def clear_orders(group)
        Lita.redis.set("#{@@REDIS_PREFIX}-#{group}-orders",[])
      end

      def send_coffee_message(user,purchaser,message)
        myuser = Lita::User.find_by_name(user)
        msg = Lita::Message.new(robot,'',Lita::Source.new(user: myuser))
        msg.reply("#{purchaser} has bought you a (coffee)!")
        msg.reply(message) # what happens if message is nil?
      rescue => e
        Lita.logger.error("Coffee#send_coffee_message raised #{e.class}: #{e.message}\n#{e.backtrace}")
      end


    end

    Lita.register_handler(Coffee)
  end
end
