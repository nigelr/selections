require 'rails/generators'
require 'rails/generators/migration'
require 'rails/generators/active_record'

class SelectionsScaffoldGenerator < Rails::Generators::Base
  include Rails::Generators::Migration

  source_root File.expand_path('../templates', __FILE__)

  def self.next_migration_number(path)
    ActiveRecord::Generators::Base.next_migration_number(path)
  end

  def generate_selections_scaffold
    {
        'selection_spec.rb' => 'spec/models/',
        'selection.rb' => 'app/models/',
        'selections_controller_spec.rb' => 'spec/controllers/',
        'selections_controller.rb' => 'app/controllers/',
        'selections_helper.rb' => 'app/helpers/',
        'selections.yml' => 'spec/fixtures/',
        '_form.html.haml' => 'app/views/selections/',
        'edit.html.haml' => 'app/views/selections/',
        'index.html.haml' => 'app/views/selections/',
        'new.html.haml' => 'app/views/selections/'
    }.each_pair do |file, dir|
      copy_file file, dir + file
    end

    migration_template 'create_selections.rb', 'db/migrate/create_selections.rb'

    route 'resources(:selections, only: :index) { resources :selections, except: :show }'

  end
end