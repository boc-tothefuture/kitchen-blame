# KitchenBlame

KitchenBlame is a ruby gem that analyzes test kitchen log files to identify bottlenecks in your testing process.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'kitchen_blame'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install kitchen_blame

## Usage


Commands:
  blame create LOG      - Analyze create time in a test kitchen LOG
  
  blame duration LOG    - Measure duration between all steps in a test kitchen LOG
  
  blame help [COMMAND]  - Describe available commands or one specific command
  
  blame recipe LOG      - Analyze recipe converge time in a test kitchen LOG


## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/boc-tothefuture/kitchen_blame.

