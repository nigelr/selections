module SelectionsHelper
  def selector selection
    if selection.leaf?
      link_to_unless selection.parent.try(:is_system), selection.name, edit_selection_selection_path(@parent, selection)
    else
      link_to selection.name, selection_selections_path(selection)
    end
  end
end
