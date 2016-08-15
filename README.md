# Description

Convenient removal of obsolete ActiveRecord models.

# Installation

```ruby
# Gemfile

gem "activerecord-prunable"
```

# Usage

1. Include the `Prunable` module in the ActiveRecord model that needs to be pruned.
2. Define the `:prunable` scope that returns models to prune.

   Example:

   ```ruby
   class Notification < ApplicationRecord

     include ActiveRecord::Prunable

     scope :prunable, -> { where("created_at > ?", 1.month.ago) }

     # You can also set type of removing records (:destroy or :delete).
     # By default it's :destroy
     prune_method :delete

   end
   ```

3. Add a `Prunable.prune!` call to a periodic task.

   Example:

   ```ruby
   # clockwork configuration file

   every(1.day, 'models.prune', at: '04:20', thread: true) { Prunable.prune! }
   ```

# Advanced Usage

Pruning a single model:

```ruby
SomeModel.prune!
```

Pruning multiple models:

```ruby
Prunable.prune!(SomeModel, AnotherModel)
```

Getting an array of all models that include `ActiveRecord::Prunable`:

```ruby
Prunable.models
```

Pruning all models that include `ActiveRecord::Prunable`:

```ruby
Prunable.prune!
```
