# lita-coffee

Manage your office coffee orders with ease!

## Installation

Add lita-coffee to your Lita instance's Gemfile:

``` ruby
gem "lita-coffee"
```

## Configuration

Set the default settings in your lita_config.rb (if you like)

``` ruby
config.handlers.lita-coffee.default_group = "Cool Kids"
config.handlers.lita-coffee.default_coffee = "Single origin espresso"
```

## Usage

``` ruby
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
```

## License

[MIT](http://opensource.org/licenses/MIT)
