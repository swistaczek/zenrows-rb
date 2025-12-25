# frozen_string_literal: true

require "test_helper"

class JsInstructionsTest < Minitest::Test
  def test_build_with_block
    instructions = Zenrows::JsInstructions.build do
      click ".button"
      wait 1000
    end

    assert_equal 2, instructions.size
    refute_empty instructions
  end

  def test_click
    instructions = Zenrows::JsInstructions.build { click ".submit" }

    assert_equal [{click: ".submit"}], instructions.to_a
  end

  def test_wait
    instructions = Zenrows::JsInstructions.build { wait 2000 }

    assert_equal [{wait: 2000}], instructions.to_a
  end

  def test_wait_for
    instructions = Zenrows::JsInstructions.build { wait_for ".content" }

    assert_equal [{wait_for: ".content"}], instructions.to_a
  end

  def test_wait_event
    instructions = Zenrows::JsInstructions.build { wait_event :networkidle }

    assert_equal [{wait_event: "networkidle"}], instructions.to_a
  end

  def test_fill
    instructions = Zenrows::JsInstructions.build { fill "#email", "test@example.com" }

    assert_equal [{fill: ["#email", "test@example.com"]}], instructions.to_a
  end

  def test_check_and_uncheck
    instructions = Zenrows::JsInstructions.build do
      check "#terms"
      uncheck "#newsletter"
    end

    assert_equal [{check: "#terms"}, {uncheck: "#newsletter"}], instructions.to_a
  end

  def test_select_option
    instructions = Zenrows::JsInstructions.build { select_option "#country", "US" }

    assert_equal [{select_option: ["#country", "US"]}], instructions.to_a
  end

  def test_scroll_y
    instructions = Zenrows::JsInstructions.build { scroll_y 1500 }

    assert_equal [{scroll_y: 1500}], instructions.to_a
  end

  def test_scroll_x
    instructions = Zenrows::JsInstructions.build { scroll_x 500 }

    assert_equal [{scroll_x: 500}], instructions.to_a
  end

  def test_scroll_to
    instructions = Zenrows::JsInstructions.build { scroll_to :bottom }

    assert_equal [{scroll_to: "bottom"}], instructions.to_a
  end

  def test_evaluate
    instructions = Zenrows::JsInstructions.build { evaluate "console.log('test')" }

    assert_equal [{evaluate: "console.log('test')"}], instructions.to_a
  end

  def test_frame_click
    instructions = Zenrows::JsInstructions.build { frame_click "#iframe", ".button" }

    assert_equal [{frame_click: ["#iframe", ".button"]}], instructions.to_a
  end

  def test_frame_wait_for
    instructions = Zenrows::JsInstructions.build { frame_wait_for "#iframe", ".loaded" }

    assert_equal [{frame_wait_for: ["#iframe", ".loaded"]}], instructions.to_a
  end

  def test_frame_fill
    instructions = Zenrows::JsInstructions.build { frame_fill "#iframe", "#input", "value" }

    assert_equal [{frame_fill: ["#iframe", "#input", "value"]}], instructions.to_a
  end

  def test_frame_evaluate
    instructions = Zenrows::JsInstructions.build { frame_evaluate "iframe-name", "console.log('hi')" }

    assert_equal [{frame_evaluate: ["iframe-name", "console.log('hi')"]}], instructions.to_a
  end

  def test_to_json
    instructions = Zenrows::JsInstructions.build do
      click ".btn"
      wait 500
    end

    json = instructions.to_json

    assert_equal '[{"click":".btn"},{"wait":500}]', json
  end

  def test_chaining
    instructions = Zenrows::JsInstructions.new
      .click(".btn")
      .wait(1000)
      .scroll_to(:bottom)

    assert_equal 3, instructions.size
  end

  def test_complex_flow
    instructions = Zenrows::JsInstructions.build do
      wait_for ".login-form"
      fill "#email", "user@example.com"
      fill "#password", "secret123"
      click "#submit"
      wait 2000
      wait_for ".dashboard"
    end

    assert_equal 6, instructions.size
  end
end
