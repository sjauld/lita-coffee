module Lita
  module Handlers
    class Coffee < Handler
      # Configuration - not required YET

      require 'json'

      route(
        /\(coffee\)(\s+\-[bcis]|\s+\+)?(.*)/i,
        :coffee,
        help: {
          '(coffee)' => "List the coffee orders",
          '(coffee) -s Colombian Filter' => "Set your coffee preference",
          '(coffee) +' => "Order a coffee",
          '(coffee) -c' => "Cancel your coffee order",
          '(coffee) -b' => "Buy coffee and clear the orders",
          '(coffee) -i' => "Remind you what your standing order is"
        }
      )

      def coffee(response)
        set_preference  = response.matches[0][0].strip == "-s"  rescue false
        order           = response.matches[0][0].strip == "+"   rescue false
        cancel          = response.matches[0][0].strip == "-c"  rescue false
        buy_coffee      = response.matches[0][0].strip == "-b"  rescue false
        get_preference  = response.matches[0][0].strip == "-i"  rescue false
        preference      = response.matches[0][1].strip          rescue nil

        my_user = response.user.name

        # Retrieve my preference
        if get_preference
          preference = get_coffee_preference(response.user.name)
          response.reply("Your current (coffee) preference is #{preference}")
        # Set my preference
        elsif set_preference
          result = set_coffee_preference(response.user.name,preference)
          if result == "OK"
            response.reply("(coffee) preference set to #{preference}")
          else
            response.reply("(sadpanda) Failed to set your (coffee) preference for some reason: #{result.inspect}")
          end
        # Order a coffee
        elsif order
          result = order_coffee(response.user.name)
          if result == "OK"
            response.reply("Ordered you a (coffee)")
          else
            response.reply("(sadpanda) Failed to order your (coffee) for some reason: #{result.inspect}")
          end
        # Cancel a coffee
        elsif cancel
          result = cancel_coffee(response.user.name)
          if result == "OK"
            response.reply("Cancelled your (coffee)")
          else
            response.reply("(sadpanda) Failed to cancel your (coffee) for some reason: #{result.inspect}")
          end
        # Buy the coffees and clear the orders
        elsif buy_coffee
          response.reply("Thanks for ordering the (coffee)!\n--")
          get_coffee_orders.each do |order|
            response.reply("#{order}: #{get_coffee_preference(order)}")
            send_coffee_message(order,response.user.name)
          end
          result = clear_orders
          if result == "OK"
            response.reply("Cleared all (coffee) orders")
          else
            response.reply("(sadpanda) Failed to celar the (coffee) orders for some reason: #{result.inspect}")
          end
        # List the orders
        else
          response.reply("Current (coffee) orders:-\n--")
          get_coffee_orders.each do |order|
            response.reply("#{order}: #{get_coffee_preference(order)}")
          end
        end



        response.reply("(coffee) is yum")

      end

      #######
      private
      #######

      def get_coffee_orders
        JSON.parse(Lita.redis.get("coffee-orders")) rescue []
      end

      def get_coffee_preference(user)
        Lita.redis.get("coffee-preference-#{user}")
      end

      def set_coffee_preference(user,preference)
        Lita.redis.set("coffee-preference-#{user}",preference)
      end

      def order_coffee(user)
        orders = get_coffee_orders
        orders << user
        orders.uniq!
        Lita.redis.set("coffee-orders",orders)
      end

      def cancel_coffee(user)
        orders = get_coffee_orders
        orders.delete(user)
        Lita.redis.set("coffee-orders",orders)
      end

      def clear_orders(user)
        Lita.redis.set("coffee-orders",[])
      end

      def send_coffee_message(user,purchaser)
        myuser = Lita::User.find_by_name(user)
        msg = Lita::Message.new(robot,'',Lita::Source.new(user: myuser))
        msg.reply("#{purchaser} has bought you a (coffee)!")
      rescue => e
        Lita.logger.error("Coffee#send_coffee_message raised #{e.class}: #{e.message}\n#{e.backtrace}")
      end


    end

    Lita.register_handler(Coffee)
  end
end
