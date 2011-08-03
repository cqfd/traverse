$:.push '../'
require 'traverse'

gem 'minitest'
require 'minitest/autorun'
require 'minitest/pride'

xml = %{
  <book title="Vineland" author="Thomas Pynchon">
    <author name="Thomas Pynchon">
      <book> V </book>
      <book> The Crying of Lot 49 </book>
      <book> Gravity's Rainbow" </book>
      <book> Slow Learner" </book>
      <book> Vineland </book>
      <book> Mason &amp; Dixon </book>
      <book> Against the Day </book>
      <book> Inherent Vice </book>
    </author>
    <epigraph author="Johnny Copeland">
      Every dog has his day,
      and a good dog
        just might have two days.
    </epigraph>
    <quotations>
      <quotation>
        Up and down that street, she remembered, television screens had
        flickered silent blue in the darkness. Strange loud birds, not of the
        neighborhood, were attracted, some content to perch in the palm
        trees, keeping silence and an eye out for the rats who lived in the
        fronds, others flying by close to windows, seeking an angle to sit
        and view the picture from. When the commercials came on, the birds,
        with voices otherworldly pure, would sing back at them, sometimes
        even when none were on.
      </quotation>
      <quotation>
        Takeshi recognized his acquaintance Minoru, a government bomb-squad
        expert. Not a genius, exactly, more like an idiot savant with X-ray
        vision.
      </quotation>
    </quotes>
    <review reviewer="Salman Rushdie">
      What is interesting is to have before us, at the end of the Greed
      Decade, that rarest of birds: a major political novel about what
      America has been doing to itself, to its children, all these many
      years.
    </review>
    <pagecount>
      385
    </pagecount>
    <text text="seriously, who writes XML like this">
      I mean, rilly.
    </text>
  </book>
}

describe Traverse::Document do
  before do
    @doc = Traverse::Document.new xml
  end

  it "helps you access attributes" do
    @doc.book.title.must_equal "Vineland"
  end

  it "also helps you access attributes shadowed by children" do
    @doc.book.author.wont_equal "Thomas Pynchon"
    @doc.book['author'].must_equal "Thomas Pynchon"
    @doc.book.author.name.must_equal "Thomas Pynchon"
  end

  describe "Support for the Enumerable module" do

    it "gives you access to the current node's attributes" do
      @doc.book.attributes.any? do |name, value|
        value == "Vineland"
      end.must_equal true
    end

    it "gives you access to the current node's children as traversable documents" do
      assert @doc.book.children.any? do |child|
        child.attributes.any? do |name, value|
          name == "reviewer" and value == "Salman Rushdie"
        end
      end
    end

  end

  it "helps you traverse to child nodes" do
    @doc.book.review.reviewer.must_equal "Salman Rushdie"
    @doc.book.epigraph.author.must_equal "Johnny Copeland"
  end

  it "knows when a node contains only text" do
    assert @doc.book.epigraph.send(:text_node?)
  end

  it "handles annoying text nodes transparently" do
    @doc.book.epigraph.text.must_match(/Every dog has his day/)
    @doc.book.review.text.must_match(/that rarest of birds/)
  end

  it "nevertheless handles attributes named 'text'" do
    @doc.book.text['text'].must_match(/seriously/)
    @doc.book.text.text.must_match(/rilly/)
  end

  it "knows when a node has only text and no attributes" do
    @doc.book.pagecount.must_equal "385"
  end

  it "knows to collect children with the same name" do
    @doc.book.author.books.count.must_equal 8
    assert @doc.book.author.books.all? do |book|
      book.is_a? String
    end
  end

  it "knows to collect children of a pluralized parent" do
    @doc.book.quotations.count.must_equal 2
    @doc.book.quotations.last.text.must_match(/more like an idiot savant/)
  end
end
