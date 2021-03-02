require 'spec_helper'

describe ActiveRecord::FilterableBy do
  let(:alice) { AUTHORS[:alice] }
  let(:bob)   { AUTHORS[:bob] }

  let(:apost) { POSTS[:alices] }
  let(:bpost) { POSTS[:bobs] }

  it 'has config' do
    expect(Comment.send(:_filterable_by_config).count).to eq(3)
    expect(Rating.send(:_filterable_by_config).count).to eq(2)
    expect(Post.send(:_filterable_by_config).count).to eq(2)
  end

  it 'ignores bad inputs' do
    expect(Comment.filter_by.count).to eq(4)
    expect(Comment.filter_by(nil).count).to eq(4)
    expect(Comment.filter_by(nil, extra: true).count).to eq(4)
    expect(Comment.filter_by('bad').count).to eq(4)

    expect(Comment.filter_by('author_id' => '').count).to eq(4)
    expect(Comment.filter_by('author_id' => []).count).to eq(4)
  end

  it 'generates simple scopes' do
    expect(Comment.filter_by('author_id' => alice.id).pluck(:title)).to match_array(%w[AA AB])
    expect(Comment.filter_by('author_id' => bob.id).pluck(:title)).to match_array(%w[BA BB])
    expect(Comment.filter_by('author_id' => [alice.id, '']).pluck(:title)).to match_array(%w[AA AB])

    expect(Comment.filter_by('post_id' => apost.id).pluck(:title)).to match_array(%w[AA BA])
    expect(Comment.filter_by('post_id' => bpost.id).pluck(:title)).to match_array(%w[AB BB])

    expect(Comment.filter_by('post_author_id' => alice.id).pluck(:title)).to match_array(%w[AA BA])
    expect(Comment.filter_by('post_author_id' => bob.id).pluck(:title)).to match_array(%w[AB BB])

    expect(Rating.filter_by('author_id' => alice.id).count).to eq(0)
    expect(Rating.filter_by('author_id' => bob.id).count).to eq(1)

    expect(Post.filter_by('author_id' => bob.id).count).to eq(1)
  end

  it 'generates combined scopes' do
    expect(Comment.filter_by('author_id' => alice.id, 'post_id' => apost.id).pluck(:title)).to match_array(['AA'])
    expect(Comment.filter_by('author_id' => alice.id, 'post_id' => bpost.id).pluck(:title)).to match_array(['AB'])
    expect(Comment.filter_by('author_id' => bob.id, 'post_id' => apost.id).pluck(:title)).to match_array(['BA'])
    expect(Comment.filter_by('author_id' => bob.id, 'post_id' => bpost.id).pluck(:title)).to match_array(['BB'])

    scope = Comment.filter_by('author_id' => [alice.id, bob.id], 'post_id' => bpost.id)
    expect(scope.pluck(:title)).to match_array(%w[AB BB])
  end

  it 'combines with other scopes' do
    scope = Comment.where(author_id: alice.id).filter_by('post_id' => apost.id)
    expect(scope.pluck(:title)).to match_array(['AA'])
  end

  it 'allows custom options' do
    scope = Post.filter_by({ 'only' => 'me' }, user_id: alice.id)
    expect(scope).to match_array([apost])

    scope = Post.filter_by({ 'only' => '??' }, user_id: alice.id)
    expect(scope.count).to eq(2)

    scope = Post.filter_by({ 'only' => 'me' })
    expect(scope.count).to eq(0)
  end

  it 'allows custom options from params' do
    filter = { 'only' => 'me' }
    expect(Post.filter_by(filter, user_id: alice.id)).to match_array([apost])
    expect(Post.filter_by(filter).count).to eq(0)
  end

  it 'ignores invalid scopes' do
    expect(Comment.filter_by('invalid' => 1).count).to eq(4)
    expect(Post.filter_by('post_id' => bpost.id).count).to eq(2)
    expect(Rating.filter_by('post_author_id' => bob.id).count).to eq(1)
  end
end
