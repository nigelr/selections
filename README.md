# Selections

TODO: Write a gem description

## Installation

Add this line to your application's Gemfile:

    gem 'selections'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install selections

## Usage

## Configuration

If you use a class name other than `Selection` as your selection model, you must
tell selections so by adding the following to a new file, `config/initializers/selections.rb`:

```ruby
Selections.model { YourSelectionModel }
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
