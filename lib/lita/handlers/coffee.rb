module Lita
  module Handlers
    class Coffee < Handler
      # Configuration - not required

      route(
        /(coffee)/i,
        :coffee,
        help: {
          '(coffee)' => "Coffee is yum"
        }
      )

      def coffee(response)
        response.reply("(coffee) is yum")
      end



    end

    Lita.register_handler(Coffee)
  end
end
