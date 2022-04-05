ENV['RACK_ENV'] ||= 'test'
require 'filterable-by'
require 'rspec'

ActiveRecord::Base.configurations = { 'test' => { 'adapter' => 'sqlite3', 'database' => ':memory:' } }
ActiveRecord::Base.establish_connection :test

ActiveRecord::Base.connection.instance_eval do
  create_table :authors do |_|
    # no columns
  end
  create_table :posts do |t|
    t.integer :author_id, null: false
  end
  create_table :feedbacks do |t|
    t.string  :type, null: false
    t.string  :title
    t.integer :stars, null: false, default: 0
    t.integer :post_id, null: false
    t.integer :author_id, null: false
  end
end

class Author < ActiveRecord::Base
  has_many :posts
end

class AbstractPost < ActiveRecord::Base
  self.abstract_class = true
  filterable_by :author_id
end

class Post < AbstractPost
  belongs_to :author

  filterable_by :only do |value, **opts|
    case value
    when 'me'
      where(author_id: opts[:user_id]) if opts[:user_id]
    else
      all
    end
  end
end

class Feedback < ActiveRecord::Base
  belongs_to :author
  belongs_to :post

  filterable_by :post_id, :author_id

  ActiveSupport::Deprecation.silence do
    filterable_by :deprecated do |scope, value|
      scope.where(author_id: value)
    end
    filterable_by :deprecated_with_opts do |scope, value, **_opts|
      scope.where(author_id: value)
    end
  end
end

class Comment < Feedback
  filterable_by :post_author_id do |value|
    joins(:post).where(Post.arel_table[:author_id].eq(value))
  end
end

class Rating < Feedback
end

AUTHORS = {
  alice: Author.create!,
  bob: Author.create!,
}.freeze

POSTS = {
  alices: Post.create!(author_id: AUTHORS[:alice].id),
  bobs: Post.create!(author_id: AUTHORS[:bob].id),
}.freeze

COMMENTS = {
  alice_on_alice: Comment.create!(title: 'AA', post_id: POSTS[:alices].id, author_id: AUTHORS[:alice].id),
  bob_on_alice: Comment.create!(title: 'BA', post_id: POSTS[:alices].id, author_id: AUTHORS[:bob].id),
  alice_on_bob: Comment.create!(title: 'AB', post_id: POSTS[:bobs].id, author_id: AUTHORS[:alice].id),
  bob_on_bob: Comment.create!(title: 'BB', post_id: POSTS[:bobs].id, author_id: AUTHORS[:bob].id),
  boa_rating: Rating.create!(stars: 5, post_id: POSTS[:alices].id, author_id: AUTHORS[:bob].id),
}.freeze
