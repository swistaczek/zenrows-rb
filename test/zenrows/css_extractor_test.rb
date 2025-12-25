# frozen_string_literal: true

require "test_helper"

class CssExtractorTest < Minitest::Test
  def test_build_with_block
    extractor = Zenrows::CssExtractor.build do
      extract :title, "h1"
      extract :price, ".price"
    end

    assert_equal({title: "h1", price: ".price"}, extractor.to_h)
  end

  def test_extract_with_attribute
    extractor = Zenrows::CssExtractor.new
    extractor.extract(:link, "a.main", attribute: "href")

    assert_equal({link: "a.main @href"}, extractor.to_h)
  end

  def test_links_helper
    extractor = Zenrows::CssExtractor.new
    extractor.links(:nav_links, "nav a")

    assert_equal({nav_links: "nav a @href"}, extractor.to_h)
  end

  def test_images_helper
    extractor = Zenrows::CssExtractor.new
    extractor.images(:product_images, "img.product")

    assert_equal({product_images: "img.product @src"}, extractor.to_h)
  end

  def test_chaining
    extractor = Zenrows::CssExtractor.new
      .extract(:title, "h1")
      .extract(:price, ".price")
      .links(:links, "a")

    assert_equal 3, extractor.size
  end

  def test_to_json
    extractor = Zenrows::CssExtractor.build do
      extract :title, "h1"
      extract :link, "a", attribute: "href"
    end

    json = extractor.to_json
    parsed = JSON.parse(json)

    assert_equal "h1", parsed["title"]
    assert_equal "a @href", parsed["link"]
  end

  def test_empty
    extractor = Zenrows::CssExtractor.new

    assert_empty extractor

    extractor.extract(:title, "h1")

    refute_empty extractor
  end

  def test_size
    extractor = Zenrows::CssExtractor.build do
      extract :one, ".one"
      extract :two, ".two"
      extract :three, ".three"
    end

    assert_equal 3, extractor.size
  end

  def test_string_name_converted_to_symbol
    extractor = Zenrows::CssExtractor.new
    extractor.extract("title", "h1")

    assert_equal({title: "h1"}, extractor.to_h)
  end
end
