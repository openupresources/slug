# encoding: utf-8

require File.dirname(__FILE__) + '/test_helper'

class SlugTest < ActiveSupport::TestCase
  describe 'slug' do
    it "bases slug on specified source column" do
      Article.delete_all
      article = Article.create!(:headline => 'Test Headline')
      assert_equal 'test-headline', article.slug
    end

    it "bases slug on specified source column, even if it is defined as a method rather than database attribute" do
      Article.delete_all
      article = Event.create!(:title => 'Test Event', :location => 'Portland')
      assert_equal 'test-event-portland', article.slug
    end

    describe "slug column" do
      it "saves slug to 'slug' column by default" do
        Article.delete_all
        article = Article.create!(:headline => 'Test Headline')
        assert_equal 'test-headline', article.slug
      end

      it "saves slug to :column specified in options" do
        Person.delete_all
        person = Person.create!(:name => 'Test Person')
        assert_equal 'test-person', person.web_slug
      end
    end
  end

  describe "column validations" do
    it "raises ArgumentError if an invalid source column is passed" do
      Company.slug(:invalid_source_column)
      assert_raises(ArgumentError) { Company.create! }
    end

    it "raises an ArgumentError if an invalid slug column is passed" do
      Company.slug(:name, :column => :bad_slug_column)
      assert_raises(ArgumentError) { Company.create! }
    end
  end

  describe 'validation' do
    it "sets validation error if source column is empty" do
      Article.delete_all
      article = Article.create
      assert !article.valid?
      assert article.errors[:slug]
    end

    it "sets validation error if normalization makes source value empty" do
      Article.delete_all
      article = Article.create(:headline => '$$$')
      assert !article.valid?
      assert article.errors[:slug]
    end

    it "doesn't update the slug even if the source column changes" do
      Article.delete_all
      article = Article.create!(:headline => 'Test Headline')
      article.update_attributes!(:headline =>  'New Headline')
      assert_equal 'test-headline', article.slug
    end

    it "validates slug format on save" do
      Article.delete_all
      article = Article.create!(:headline => 'Test Headline')
      article.slug = 'A BAD $LUG.'

      assert !article.valid?
      assert article.errors[:slug].present?
    end

    it "validates uniqueness of slug by default" do
      Article.delete_all
      Article.create!(:headline => 'Test Headline')
      article2 = Article.create!(:headline => 'Test Headline')
      article2.slug = 'test-headline'

      assert !article2.valid?
      assert article2.errors[:slug].present?
    end

    it "uses validate_uniqueness_if proc to decide whether uniqueness validation applies" do
      Post.create!(:headline => 'Test Headline')
      article2 = Post.new
      article2.slug = 'test-headline'

      assert article2.valid?
    end

    it "doesn't overwrite slug value on create if it was already specified" do
      Article.delete_all
      a = Article.create!(:headline => 'Test Headline', :slug => 'slug1')
      assert_equal 'slug1', a.slug
    end
  end

  describe "resetting a slug" do
    before do
      Article.delete_all
      @article = Article.create(:headline => 'test headline')
      @original_slug = @article.slug
    end

    it "maintains the same slug if slug column hasn't changed" do
      @article.reset_slug
      assert_equal @original_slug, @article.slug
    end

    it "changes slug if slug column has updated" do
      @article.headline = "donkey"
      @article.reset_slug
      refute_equal(@original_slug, @article.slug)
    end

    it "maintains sequence" do
      @existing_article = Article.create!(:headline => 'world cup')
      @article.headline = "world cup"
      @article.reset_slug
      assert_equal 'world-cup-1', @article.slug
    end
  end

  describe "slug normalization" do
    it "lowercases strings" do
      Article.delete_all
      @article = Article.new
      @article.headline = 'AbC'
      @article.save!
      assert_equal "abc", @article.slug
    end

    it "replaces whitespace with dashes" do
      Article.delete_all
      @article = Article.new
      @article.headline = 'a b'
      @article.save!
      assert_equal 'a-b', @article.slug
    end

    it "replaces 2spaces with 1dash" do
      Article.delete_all
      @article = Article.new
      @article.headline = 'a  b'
      @article.save!
      assert_equal 'a-b', @article.slug
    end

    it "removes punctuation" do
      Article.delete_all
      @article = Article.new
      @article.headline = 'abc!@#$%^&*•¶§∞¢££¡¿()><?""\':;][]\.,/'
      @article.save!
      assert_match 'abc', @article.slug
    end

    it "strips trailing space" do
      Article.delete_all
      @article = Article.new
      @article.headline = 'ab '
      @article.save!
      assert_equal 'ab', @article.slug
    end

    it "strips leading space" do
      Article.delete_all
      @article = Article.new
      @article.headline = ' ab'
      @article.save!
      assert_equal 'ab', @article.slug
    end

    it "strips trailing dashes" do
      Article.delete_all
      @article = Article.new
      @article.headline = 'ab-'
      @article.save!
      assert_match 'ab', @article.slug
    end

    it "strips leading dashes" do
      Article.delete_all
      @article = Article.new
      @article.headline = '-ab'
      @article.save!
      assert_match 'ab', @article.slug
    end

    it "remove double-dashes" do
      Article.delete_all
      @article = Article.new
      @article.headline = 'a--b--c'
      @article.save!
      assert_match 'a-b-c', @article.slug
    end

    it "doesn't modify valid slug strings" do
      Article.delete_all
      @article = Article.new
      @article.headline = 'a-b-c-d'
      @article.save!
      assert_match 'a-b-c-d', @article.slug
    end

    it "doesn't insert dashes for periods in acronyms, regardless of where they appear in string" do
      Article.delete_all
      @article = Article.new
      @article.headline = "N.Y.P.D. vs. N.S.A. vs. F.B.I."
      @article.save!
      assert_match 'nypd-vs-nsa-vs-fbi', @article.slug
    end

    it "doesn't insert dashes for apostrophes" do
      Article.delete_all
      @article = Article.new
      @article.headline = "Thomas Jefferson's Papers"
      @article.save!
      assert_match 'thomas-jeffersons-papers', @article.slug
    end

    it "preserves numbers in slug" do
      Article.delete_all
      @article = Article.new
      @article.headline = "2010 Election"
      @article.save!
      assert_match '2010-election', @article.slug
    end
  end

  describe "diacritics handling" do
    it "strips diacritics" do
      Article.delete_all
      @article = Article.new
      @article.headline = "açaí"
      @article.save!
      assert_equal "acai", @article.slug
    end

    it "strips diacritics correctly " do
      Article.delete_all
      @article = Article.new
      @article.headline  = "ÀÁÂÃÄÅÆÇÈÊËÌÍÎÏÐÑÒÓÔÕÖØÙÚÛÜÝÞßàáâãäåæçèéêëìíîïðñòóôõöøùúûüýþÿ"
      @article.save!
      expected = "aaaaaaaeceeeiiiidnoooooouuuuythssaaaaaaaeceeeeiiiidnoooooouuuuythy".split(//)
      output = @article.slug.split(//)
      output.each_index do |i|
        assert_equal expected[i], output[i]
      end
    end
  end

  describe "sequence handling" do
    it "doesn't add a sequence if saving first instance of slug" do
      Article.delete_all
      article = Article.create!(:headline => 'Test Headline')
      assert_equal 'test-headline', article.slug
    end

    it "assigns a -1 suffix to the second instance of the slug" do
      Article.delete_all
      Article.create!(:headline => 'Test Headline')
      article_2 = Article.create!(:headline => 'Test Headline')
      assert_equal 'test-headline-1', article_2.slug
    end

    it 'assigns a -2 suffux to the third instance of the slug containing numbers' do
      Article.delete_all
      2.times { |i| Article.create! :headline => '11111' }
      article_3 = Article.create! :headline => '11111'
      assert_equal '11111-2', article_3.slug
    end

    it "knows about single table inheritance" do
      Article.delete_all
      article = Article.create!(:headline => 'Test Headline')
      story = Storyline.create!(:headline => article.headline)
      assert_equal 'test-headline-1', story.slug
    end

    it "correctly slugs for partial matches" do
      Article.delete_all
      rap_metal = Article.create!(:headline => 'Rap Metal')
      assert_equal 'rap-metal', rap_metal.slug

      rap = Article.create!(:headline => 'Rap')
      assert_equal('rap', rap.slug)
    end

    it "assigns a -12 suffix to the thirteenth instance of the slug" do
      Article.delete_all
      12.times { |i| Article.create!(:headline => 'Test Headline') }
      article_13 = Article.create!(:headline => 'Test Headline')
      assert_equal 'test-headline-12', article_13.slug

      12.times { |i| Article.create!(:headline => 'latest from lybia') }
      article_13 = Article.create!(:headline => 'latest from lybia')
      assert_equal 'latest-from-lybia-12', article_13.slug
    end

    it 'assigns a -2 suffux to the third instance of the slug containing numbers' do
      Article.delete_all
      2.times { |i| Article.create! :headline => '11111' }
      article_3 = Article.create! :headline => '11111'
      assert_equal '11111-2', article_3.slug
    end
  end
end
