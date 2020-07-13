require File.dirname(__FILE__) + '/spec_helper'

describe ActiveRecord::FilterableBy do
  let(:alice) { AUTHORS[:alice] }
  let(:bob)   { AUTHORS[:bob] }

  let(:apost) { POSTS[:alices] }
  let(:bpost) { POSTS[:bobs] }

  it 'should have config' do
    expect(Comment.send(:_filterable_by_config).count).to eq(3)
    expect(Rating.send(:_filterable_by_config).count).to eq(2)
    expect(Post.send(:_filterable_by_config).count).to eq(1)
  end

  it 'should ignore bad inputs' do
    expect(Comment.filter_by(nil).count).to eq(4)
    expect(Comment.filter_by.count).to eq(4)

    expect(Comment.filter_by('author_id' => '').count).to eq(4)
    expect(Comment.filter_by('author_id' => []).count).to eq(4)
  end

  it 'should generate simple scopes' do
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

  it 'should generate combined scopes' do
    expect(Comment.filter_by('author_id' => alice.id, 'post_id' => apost.id).pluck(:title)).to match_array(['AA'])
    expect(Comment.filter_by('author_id' => alice.id, 'post_id' => bpost.id).pluck(:title)).to match_array(['AB'])
    expect(Comment.filter_by('author_id' => bob.id, 'post_id' => apost.id).pluck(:title)).to match_array(['BA'])
    expect(Comment.filter_by('author_id' => bob.id, 'post_id' => bpost.id).pluck(:title)).to match_array(['BB'])

    scope = Comment.filter_by('author_id' => [alice.id, bob.id], 'post_id' => bpost.id)
    expect(scope.pluck(:title)).to match_array(%w[AB BB])
  end

  it 'should combine with other scopes' do
    scope = Comment.where(author_id: alice.id).filter_by('post_id' => apost.id)
    expect(scope.pluck(:title)).to match_array(['AA'])
  end

  it 'should allow custom options' do
    scope = Author.filter_by({ 'only' => 'me' }, id: alice.id)
    expect(scope.to_a).to match_array([alice])

    scope = Author.filter_by({ 'only' => '??' }, id: alice.id)
    expect(scope.to_a).to match_array([alice, bob])

    scope = Author.filter_by({ 'only' => 'me' })
    expect(scope.to_a).to match_array([alice, bob])
  end

  it 'should ignore invalid scopes' do
    expect(Comment.filter_by('invalid' => 1).count).to eq(4)
    expect(Post.filter_by('post_id' => bpost.id).count).to eq(2)
    expect(Rating.filter_by('post_author_id' => bob.id).count).to eq(1)
  end
end
