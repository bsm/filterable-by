# Filterable By

ActiveRecord plugin to parse e.g. a `filter` query parameter apply scopes. Useful for [JSON-API][jsonapi] compatibility.

[jsonapi]: http://jsonapi.org/format/#fetching-filtering

## Installation

Add `gem 'filterable-by'` to your Gemfile.

## Usage

```ruby
class Comment < ActiveRecord::Base
  belongs_to :post

  filterable_by :post_id, :user_id
  filterable_by :post_author_id do |scope, value|
    scope.joins(:posts).where(:'posts.author_id' => value)
  end
  filterable_by :only do |scope, value, **opts|
    case value
    when 'mine'
      scope.where(author: opts[:user])
    else
      scope
    end
  end
end

Comment.filter_by(params[:filter], user: current_user.email)  # => ActiveRecord::Relation
```

Simple use cases:

```ruby
Comment.filter_by({ 'post_id' => '1' })
# => WHERE post_id = 1

Comment.filter_by({ 'user_id' => '2', 'ignored' => '3' })
# => WHERE user_id = 2

Comment.filter_by({ 'only' => 'mine' }, user: 'alice')
# => WHERE author = 'alice'

Comment.filter_by({ 'post_author_id' => '5' })
# => JOINS posts ON posts.id = comments.post_id WHERE posts.author_id = 5
```
