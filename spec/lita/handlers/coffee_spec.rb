require "spec_helper"
#TODO: write this stuff

describe Lita::Handlers::Coffee, lita_handler: true do

  it { is_expected.to route('(coffee)').to(:coffee) }
  it { is_expected.to route('coffee').to(:coffee) }

  describe '#coffee' do
    before{robot.trigger(:loaded)}

    it 'sets up a user if they do not exist already' do
      send_message("coffee")
      expect(replies.first).to start_with("Welcome to coffee!")
    end

    it 'lists the current coffee orders if no options received' do
      send_message("coffee")
      expect(replies.last).to start_with("Current orders")
    end

    it 'orders me a coffee if I ask it!' do
      send_message("coffee +")
      expect(replies.last).to eq("Ordered you a coffee")
      send_message("coffee")
      expect(replies.last).to start_with("Test User:")
    end

    it 'displays my profile settings' do
      send_message("coffee -i")
      expect(replies.last).to start_with("Your current coffee is")
    end

    it 'sets my coffee preference' do
      send_message("coffee -s decaf soy cappuccino")
      expect(replies.last).to eq("Coffee set to decaf soy cappuccino")
      send_message("coffee -i")
      expect(replies.last).to start_with("Your current coffee is decaf soy cappuccino")
    end

    it 'changes my coffee group' do
      send_message("coffee -g testing team")
      expect(replies.last).to eq("Group set to testing team")
      send_message("coffee -i")
      expect(replies.last).to end_with("You are in the testing team group.")
    end

    it 'cancels my order' do
      send_message("coffee +")
      order_a_coffee('stu')
      order_a_coffee('joel')
      expect(coffees_in_the_queue).to eq(3)
      send_message("coffee -c")
      expect(replies.last).to eq("Cancelled your coffee") #TODO: check that my name has been removed from the queue
      expect(coffees_in_the_queue).to eq(2)
    end

    it 'deletes me from the system' do
      send_message("coffee -d")
      expect(replies.last).to eq("You have been deleted from coffee")
    end

    it 'displays default settings' do
      send_message("coffee -t")
      expect(replies.last).to start_with("Default coffee:")
    end

    it 'buys the coffees and clears the queue' do
      order_a_coffee('stu')
      order_a_coffee('joel')
      send_message("coffee -b")
      expect(replies.last).to start_with("Cleared all orders")
      send_message("coffee")
      expect(replies.last).to end_with("--")
      expect(replies.select{|x| x == "Test User has bought you a coffee!"}.count).to eq(2)
    end

    def order_a_coffee(user)
      user = Lita::User.create(1,name: user)
      send_message('coffee +', as: user)
    end

    def coffees_in_the_queue
      send_message('coffee')  
      replies.reverse.slice(0,replies.reverse.index{|x| ( x =~ /^Current orders/ ) == 0}).count
    end





  end
end
