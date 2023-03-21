require 'spec_helper'

describe ActiveRecord::FilterableBy do
  let(:alice) { AUTHORS[:alice] }
  let(:bob)   { AUTHORS[:bob] }

  let(:apost) { POSTS[:alices] }
  let(:bpost) { POSTS[:bobs] }

  it 'has config' do
    expect(Comment.send(:_filterable_by_config).count).to eq(5)
    expect(Rating.send(:_filterable_by_config).count).to eq(4)
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
    expect(Comment.filter_by('author_id' => alice.id, 'post_id' => apost.id).pluck(:title)).to contain_exactly('AA')
    expect(Comment.filter_by('author_id' => alice.id, 'post_id' => bpost.id).pluck(:title)).to contain_exactly('AB')
    expect(Comment.filter_by('author_id' => bob.id, 'post_id' => apost.id).pluck(:title)).to contain_exactly('BA')
    expect(Comment.filter_by('author_id' => bob.id, 'post_id' => bpost.id).pluck(:title)).to contain_exactly('BB')

    scope = Comment.filter_by('author_id' => [alice.id, bob.id], 'post_id' => bpost.id)
    expect(scope.pluck(:title)).to match_array(%w[AB BB])
  end

  it 'generates negated scopes' do
    expect(Comment.filter_by('author_id_not' => alice.id).pluck(:title)).to match_array(%w[BA BB])
    expect(Comment.filter_by('author_id_not' => [alice.id, bob.id]).pluck(:title)).to match_array(%w[])
    expect(Comment.filter_by('post_id_not' => apost.id).pluck(:title)).to match_array(%w[AB BB])
    expect(Comment.filter_by('post_author_id_not' => alice.id).pluck(:title)).to match_array(%w[AB BB])
    expect(Comment.filter_by('author_id' => bob.id, 'post_id_not' => bpost.id).pluck(:title)).to contain_exactly('BA')
  end

  it 'combines with other scopes' do
    scope = Comment.where(author_id: alice.id).filter_by('post_id' => apost.id)
    expect(scope.pluck(:title)).to contain_exactly('AA')

    expect(alice.posts.filter_by('post_id' => apost.id).count).to be(1)
    expect(alice.posts.filter_by('author_id' => alice.id).count).to be(1)
    expect(alice.posts.filter_by('author_id_not' => bob.id).count).to be(1)
    expect(alice.posts.filter_by('author_id' => bob.id).count).to be_zero
    expect(alice.posts.filter_by('author_id_not' => alice.id).count).to be_zero
  end

  it 'allows custom options' do
    scope = Post.filter_by({ 'only' => 'me' }, user_id: alice.id)
    expect(scope).to contain_exactly(apost)

    scope = Post.filter_by({ 'only' => '??' }, user_id: alice.id)
    expect(scope.count).to eq(2)

    scope = Post.filter_by({ 'only' => 'me' })
    expect(scope.count).to eq(0)
  end

  it 'allows custom options from params' do
    filter = { 'only' => 'me' }
    expect(Post.filter_by(filter, user_id: alice.id)).to contain_exactly(apost)
    expect(Post.filter_by(filter).count).to eq(0)
  end

  it 'ignores invalid scopes' do
    expect(Comment.filter_by('invalid' => 1).count).to eq(4)
    expect(Post.filter_by('post_id' => bpost.id).count).to eq(2)
    expect(Rating.filter_by('post_author_id' => bob.id).count).to eq(1)
  end

  it 'supports deprecated scoping' do
    expect(Comment.filter_by('deprecated' => alice.id).pluck(:title)).to match_array(%w[AA AB])
    expect(Comment.filter_by('deprecated_with_opts' => alice.id).pluck(:title)).to match_array(%w[AA AB])
    expect(Comment.filter_by('deprecated_not' => alice.id).pluck(:title)).to match_array(%w[BA BB])
  end

  it 'supports abstract classes' do
    expect(Post.filter_by('author_id' => bob.id).count).to eq(1)
  end
end
