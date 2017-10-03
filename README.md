# Activerecord-prunable [![Gem Version](https://badge.fury.io/rb/activerecord-prunable.svg)](https://badge.fury.io/rb/activerecord-prunable) [![Build Status](https://travis-ci.org/dr2m/activerecord-prunable.svg?branch=master)](https://travis-ci.org/dr2m/activerecord-prunable) [![Code Climate](https://codeclimate.com/github/dr2m/activerecord-prunable/badges/gpa.svg)](https://codeclimate.com/github/dr2m/activerecord-prunable)

Convenient removal of obsolete records for ActiveRecord models.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'activerecord-prunable'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install activerecord-prunable


## Usage

__1. Include the `Prunable` module in the ActiveRecord model which needs to be pruned.__

__2. Define the `:prunable` scope which returns records to prune.__

   ```ruby
   class Notification < ApplicationRecord
     include ActiveRecord::Prunable

     scope :prunable, -> { where("created_at > ?", 1.month.ago) }

     # You can also set type of removing records (:destroy or :delete).
     # By default it's :destroy
     prune_method :delete
   end
   ```

   or use one of the `prune_after`, `prune_created_after`, `prune_updated_after` methods

   ```ruby
   class Notification < ApplicationRecord
     include ActiveRecord::Prunable

      prune_after 7.days
   end
   ```

   `prune_after` is an alias for `prune_created_after`
   `prune_created_after(TTL)` defines `where('created_at < ?', current_time - TTL)` prunable scope
   `prune_updated_after(TTL)` defines `where('updated_at < ?', current_time - TTL)` prunable scope

__3. Add a `Prunable.prune!` call to a periodic task.__

   Example:

   ```ruby
   # clockwork configuration file

   every(1.day, 'models.prune', at: '04:20', thread: true) { Prunable.prune! }
   ```

   You can also inject current time `Prunable.prune!(current_time: Time.current)`

# Advanced Usage

__Pruning a single model:__

```ruby
SomeModel.prune!
```

__Pruning multiple models:__
Note that the `Prunable.prune!` calls `Rails.application.eager_load!`. It can decrease free memory size.

```ruby
Prunable.prune!(SomeModel, AnotherModel)
```

__Set default method of pruning (:destroy or :delete):__

```ruby
Prunable.prune!(prune_method: :delete)
```

__Call `:prunable` scope with params:__

```ruby
Prunable.prune!(params: [:foo, :bar])
```

__Getting an array of all the models which include `ActiveRecord::Prunable`:__
```ruby
Prunable.models
```

__Pruning all models which include `ActiveRecord::Prunable`:__

```ruby
Prunable.prune!
```
