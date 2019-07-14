require 'selections/version'
require 'active_record'
require 'action_view'

module Selections

  require 'selections/belongs_to_selection'
  require 'selections/has_many_selections'
  require 'selections/form_builder_extensions'
  require 'selections/selectable'

  # Given a block, will set how we find / detect the current model
  # used for selections, without a block, will return the value.
  # Note: Needed iff you are using a model other than Selection.
  def self.model(&block)
    if block
      @model = block
    else
      @model ||= lambda { Selection }
      @model.call
    end
  end

end
