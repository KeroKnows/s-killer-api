# frozen_string_literal: true

module Skiller
  module Representer
    # OpenStruct for deserializing json with hypermedia
    class OpenStructWithLinks < Struct
      attr_accessor :links
    end
  end
end
