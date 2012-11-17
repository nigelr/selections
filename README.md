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

First, you need to configure your selection model. We typically use `Selection` for this (although you
can change the name), and should be generated such as:

```ruby
rails generate model Selection ...
```

And next, edit this class to look like:

```ruby
class Selection < ActiveRecord::Base
  selectable
end
```

Next, you need to tell models that have a selectable association. These are `belongs_to` associations
which pull their values from the selections model. Assuming you have a `User` model with a selection association
called age bracket, you can set this up like so:

```ruby
class User < ActiveRecord::Base

  belongs_to_selection :age_bracket

end
```

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
