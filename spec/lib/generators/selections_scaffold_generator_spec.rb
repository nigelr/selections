require 'spec_helper'
require 'fileutils'
require 'generator_spec'
require 'generators/selections_scaffold/selections_scaffold_generator'

describe SelectionsScaffoldGenerator do

  destination File.expand_path("../../../../tmp", __FILE__)

  before :all do
    prepare_destination
    # the generator requires the config/routes.rb file to exist. Let's create one:
    create_routes_file
    run_generator
  end

  def create_routes_file
    @dir = self.class.test_case.destination_root
    FileUtils.mkdir_p File.join(@dir, "config")
    config = <<-EOF
Some::Application.routes.draw do
  root to: "home#index"
end
    EOF
    File.write File.join(@dir, "config", "routes.rb"), config
  end

  def file_path(path)
    File.join(@dir, path)
  end

  def file_contents(path)
    File.read(file_path(path))
  end

  it "creates the routes" do
    expect(file_contents('config/routes.rb')).to include("resources(:selections, only: :index) { resources :selections, except: :show }")
  end

  context "check files" do
    %w[
      app/controllers/selections_controller.rb
      app/helpers/selections_helper.rb
      app/models/selection.rb
      app/views/selections/_form.html.haml
      app/views/selections/edit.html.haml
      app/views/selections/index.html.haml
      app/views/selections/new.html.haml
      config/routes.rb
      spec/controllers/selections_controller_spec.rb
      spec/fixtures/selections.yml
      spec/models/selection_spec.rb
  ].each do |file|
      it "created #{file}" do
        path = File.join(@dir, file)
        expect(File.exist?(path)).to be_truthy
      end
    end
  end

  it "created one model" do
    expect(Dir["#{@dir}/app/models/*.rb"].count).to eq(1)
  end

  it "creates a migration" do
    expect(Dir["#{@dir}/db/migrate/*.rb"].count).to eq(1)
  end

  it "used the correct model" do
    model = file_contents("app/models/selection.rb")
    if ActiveRecord::VERSION::MAJOR == 3
      expect(model).to include("attr_accessible")
    else
      expect(model).not_to include("attr_accessible")
    end
  end

  it "created the routes" do
    expect(file_contents('config/routes.rb')).to include("resources(:selections, only: :index) { resources :selections, except: :show }")
  end
end
