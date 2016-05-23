ENV['RACK_ENV'] ||= 'test'
require 'filterable-by'
require 'rspec'

ActiveRecord::Base.configurations['test'] = { 'adapter' => 'sqlite3', 'database' => ':memory:' }
ActiveRecord::Base.establish_connection :test

ActiveRecord::Base.connection.instance_eval do
  create_table :authors do |_|
  end
  create_table :posts do |t|
    t.integer :author_id, null: false
  end
  create_table :comments do |t|
    t.string  :title, null: false
    t.integer :post_id, null: false
    t.integer :author_id, null: false
  end
end

class Author < ActiveRecord::Base
end

class Post < ActiveRecord::Base
  belongs_to :author

  filterable_by :author_id
end

class Comment < ActiveRecord::Base
  belongs_to :author
  belongs_to :post

  filterable_by :post_id, :author_id
  filterable_by :post_author_id do |scope, value|
    scope.joins(:post).where(Post.arel_table[:author_id].eq(value))
  end
end

AUTHORS = {
  alice: Author.create!,
  bob:   Author.create!,
}

POSTS = {
  alices: Post.create!(author_id: AUTHORS[:alice].id),
  bobs:   Post.create!(author_id: AUTHORS[:bob].id),
}

COMMENTS = {
  alice_on_alice: Comment.create!(title: 'AA', post_id: POSTS[:alices].id, author_id: AUTHORS[:alice].id),
  bob_on_alice:   Comment.create!(title: 'BA', post_id: POSTS[:alices].id, author_id: AUTHORS[:bob].id),
  alice_on_bob:   Comment.create!(title: 'AB', post_id: POSTS[:bobs].id, author_id: AUTHORS[:alice].id),
  bob_on_bob:     Comment.create!(title: 'BB', post_id: POSTS[:bobs].id, author_id: AUTHORS[:bob].id),
}
