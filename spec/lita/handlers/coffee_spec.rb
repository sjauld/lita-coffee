require "spec_helper"

describe Lita::Handlers::Coffee, lita_handler: true do

  # Sample office
  SAMPLE_DATA = [
    {name: 'stu', group: 'cool kids', coffee: 'Colombian filter'},
    {name: 'joel', group: 'cool kids', coffee: 'Strong cap w/ 1/2 sugar'},
    {name: 'arun', group: 'cool kids', coffee: 'Warragamba highball'},
    {name: 'danielle', group: 'latte socialists', coffee: 'Latte'},
    {name: 'jack', group: 'latte socialists', coffee: 'Latte'},
    {name: 'john', group: 'latte socialists', coffee: 'Latte'},
    {name: 'alex', group: 'latte socialists', coffee: 'Latte'},
    {name: 'geoff', group: 'traditionalists', coffee: 'Flat white'},
    {name: 'simon', group: 'traditionalists', coffee: 'Skim flat white'},
  ]

  it { is_expected.to route('coffee').to(:list_orders) }
  it { is_expected.to route('I really like coffee!').to(:init_user)}
  it { is_expected.to route('coffee +').to(:get_me_a_coffee)}
  it { is_expected.to route('coffee + cool dudes').to(:get_me_a_coffee)}
  it { is_expected.to route('coffee -c').to(:cancel_order)}
  it { is_expected.to route('coffee -i').to(:display_profile)}
  it { is_expected.to route('coffee -s Latte').to(:set_prefs)}
  it { is_expected.to route('coffee -g Testers').to(:set_group)}
  it { is_expected.to route('coffee -b This one is on me :)').to(:buy_coffees)}
  it { is_expected.to route('coffee -t').to(:system_settings)}
  it { is_expected.to route('coffee -d').to(:delete_me)}
  it { is_expected.to route('coffee -l').to(:list_groups)}

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

    it 'orders you a coffee if you ask it!' do
      send_message("coffee +")
      expect(replies.last).to eq("Ordered you a coffee from coffee-lovers")
      send_message("coffee")
      expect(replies.last).to start_with("Test User:")
    end

    it 'orders me a coffee from a different group too' do
      send_message("coffee + testers")
      expect(replies.last).to eq("Ordered you a coffee from testers")
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
      set_prefs('stu',{group: 'testing team'})
      expect(replies.last).to eq("Group set to testing team")
      check_prefs('stu')
      expect(replies.last).to end_with("You are in the testing team group.")
    end

    it 'cancels my order' do
      populate_the_database
      expect(coffees_in_the_queue('cool kids')).to eq(3)
      cancel_order('stu')
      expect(replies.last).to eq("Cancelled your coffee") #TODO: check that my name has been removed from the queue
      expect(coffees_in_the_queue('cool kids')).to eq(2)
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
      populate_the_database
      buy_coffees_for('cool kids')
      expect(replies.last).to start_with("Cleared all orders")
      send_message("coffee")
      expect(replies.last).to end_with("--")
      expect(replies.select{|x| x == "Test User has bought you a coffee!"}.count).to eq(3)
    end

    it 'lists the available groups' do
      populate_the_database
      send_message("coffee -l")
      expect(replies.last).to start_with("The following groups are active:-")
    end

    it 'gets some stats' do
      populate_the_database
      buy_coffees_for('cool kids')
      send_message("coffee -w cool kids")
      expect(replies.last).to start_with("Who owes whom?")
    end

    def set_prefs(name,opts={})
      user = init_user(name)
      send_message("coffee -g #{opts[:group]}", as: user) unless opts[:group].nil?
      send_message("coffee -s #{opts[:coffee]}", as: user) unless opts[:coffee].nil?
    end

    def check_prefs(name)
      user = init_user(name)
      send_message("coffee -i", as: user)
    end

    def order_a_coffee(name)
      user = init_user(name)
      send_message('coffee +', as: user)
    end

    def cancel_order(name)
      user = init_user(name)
      send_message('coffee -c', as: user)
    end

    def coffees_in_the_queue(group)
      send_message("coffee -g #{group}")
      send_message("coffee")
      replies.reverse.slice(0,replies.reverse.index{|x| ( x =~ /^Current orders/ ) == 0}).count
    end

    def populate_the_database
      SAMPLE_DATA.each do |x|
        set_prefs(x[:name],{coffee: x[:coffee],group: x[:group]})
        order_a_coffee(x[:name])
      end
    end

    def init_user(name)
      Lita::User.create(1,name: name)
    end

    def buy_coffees_for(group)
      send_message("coffee -g #{group}")
      send_message("coffee -b")
    end






  end
end
