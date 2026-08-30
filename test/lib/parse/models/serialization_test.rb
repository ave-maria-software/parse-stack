require_relative "../../../test_helper"

class SerializationTestSong < Parse::Object
  property :name
end

class TestObjectSerialization < Minitest::Test
  # ActiveModel::Dirty#as_json (added in Rails 8.1) does options[:except]
  # without a nil guard. Parse::Object#as_json used to forward a literal nil,
  # which crashed every to_json/as_json call under activemodel >= 8.1 with
  # `NoMethodError: undefined method '[]' for nil`.
  def test_as_json_with_no_arguments_does_not_raise
    song = SerializationTestSong.new name: "Sinnerman"
    json = song.as_json
    assert_kind_of Hash, json
    assert_equal "Sinnerman", json["name"]
  end

  def test_to_json_round_trips
    song = SerializationTestSong.new name: "Feeling Good"
    parsed = JSON.parse(song.to_json)
    assert_equal "Feeling Good", parsed["name"]
  end
end
