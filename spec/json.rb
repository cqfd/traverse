require 'traverse'

gem 'minitest'
require 'minitest/autorun'
require 'minitest/pride'

json = %{
  {
    "menu": {
      "id": "file",
      "value": "File",
      "popup": {
        "menuitem": [
          {"value": "New", "onclick": "CreateNewDoc()"},
          {"value": "Open", "onclick": "OpenDoc()"},
          {"value": "Close", "onclick": "CloseDoc()"}
        ]
      }
    }
  }
}

describe Traverse::Document do
  before do
    @doc = Traverse::Document.new json
  end

  describe "Grabbing simple attributes" do
    it "helps you access attributes" do
      @doc.menu.id.must_equal "file"
    end
  end

  describe "Grabbing attributes that are arrays" do
    it "knows how to handle json arrays" do
      @doc.menu.popup.menuitem.count.must_equal 3
    end

    it "traversifies the elements of json arrays" do
      @doc.menu.popup.menuitem.last.value.must_equal "Close"
    end
  end
end
