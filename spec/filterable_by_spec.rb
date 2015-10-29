require File.dirname(__FILE__) + '/spec_helper'

describe ActiveRecord::FilterableByHelper do

  let(:alice) { AUTHORS[:alice] }
  let(:bob)   { AUTHORS[:bob] }

  let(:apost) { POSTS[:alices] }
  let(:bpost) { POSTS[:bobs] }

  it 'should have config' do
    expect(Comment._filterable_by_scope_options.size).to eq(3)
  end

  it 'should ignore bad inputs' do
    expect(Comment.filter_by(nil).count).to eq(4)
    expect(Comment.filter_by({}).count).to eq(4)

    expect(Comment.filter_by('author_id' => '').count).to eq(4)
    expect(Comment.filter_by('author_id' => []).count).to eq(4)
  end

  it 'should generate simple scopes' do
    expect(Comment.filter_by('author_id' => alice.id).pluck(:title)).to match_array(['AA', 'AB'])
    expect(Comment.filter_by('author_id' => bob.id).pluck(:title)).to match_array(['BA', 'BB'])
    expect(Comment.filter_by('author_id' => [alice.id, '']).pluck(:title)).to match_array(['AA', 'AB'])

    expect(Comment.filter_by('post_id' => apost.id).pluck(:title)).to match_array(['AA', 'BA'])
    expect(Comment.filter_by('post_id' => bpost.id).pluck(:title)).to match_array(['AB', 'BB'])

    expect(Comment.filter_by('post_author_id' => alice.id).pluck(:title)).to match_array(['AA', 'BA'])
    expect(Comment.filter_by('post_author_id' => bob.id).pluck(:title)).to match_array(['AB', 'BB'])
  end

  it 'should generate combined scopes' do
    expect(Comment.filter_by('author_id' => alice.id, 'post_id' => apost.id).pluck(:title)).to match_array(['AA'])
    expect(Comment.filter_by('author_id' => alice.id, 'post_id' => bpost.id).pluck(:title)).to match_array(['AB'])
    expect(Comment.filter_by('author_id' => bob.id, 'post_id' => apost.id).pluck(:title)).to match_array(['BA'])
    expect(Comment.filter_by('author_id' => bob.id, 'post_id' => bpost.id).pluck(:title)).to match_array(['BB'])

    scope = Comment.filter_by('author_id' => [alice.id, bob.id], 'post_id' => bpost.id)
    expect(scope.pluck(:title)).to match_array(['AB', 'BB'])
  end

  it 'should combine with other scopes' do
    scope = Comment.where(author_id: alice.id).filter_by('post_id' => apost.id)
    expect(scope.pluck(:title)).to match_array(['AA'])
  end

end
