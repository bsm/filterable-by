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
    scope.joins(:posts).where(:"posts.author_id" => value)
  end
end

Comment.filter_by(params[:filter])  # => ActiveRecord::Relation
```

Simple use cases:

```ruby
Comment.filter_by({ "post_id" => "1" })
# => WHERE post_id = 1

Comment.filter_by({ "user_id" => "2", "ignored" => "3" })
# => WHERE user_id = 2

Comment.filter_by({ "post_author_id" => "5" })
# => JOINS posts ON posts.id = comments.post_id WHERE posts.author_id = 5
```

## LICENCE

```
Copyright (c) 2015 Black Square Media

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
```
