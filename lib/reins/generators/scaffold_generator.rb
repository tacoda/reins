require "reins/core/generators/blueprint"
require "reins/core/generators/blueprint_writer"
require "reins/adapters/driven/filesystem/real"
require "reins/generators/model_generator"

module Reins
  module Generators
    class ScaffoldGenerator
      ROUTES_PATH = "config/routes.rb".freeze

      def initialize(name, fields = [], file_system: Reins::Adapters::Driven::Filesystem::Real.new)
        @name = name
        @fields = fields.map { |f| f.split(":", 2) }
        @fs = file_system
      end

      def blueprint
        bp = ModelGenerator.new(@name, @fields.map { |n, t| "#{n}:#{t}" }).blueprint
        bp.add_file("app/controllers/#{table}_controller.rb", controller_content)
        view_files.each { |path, content| bp.add_file(path, content) }
        merged_routes = merged_routes_content
        bp.add_file(ROUTES_PATH, merged_routes) if merged_routes
        bp
      end

      def run(file_system: @fs)
        Reins::Core::Generators::BlueprintWriter.new(file_system).write(blueprint)
      end

      private

      def model_class
        @name.split("_").map(&:capitalize).join
      end

      def table
        pluralize(Reins.to_underscore(model_class))
      end

      def controller_class
        "#{table.split('_').map(&:capitalize).join}Controller"
      end

      def controller_content
        permitted = @fields.map { |n, _| ":#{n}" }.join(", ")
        permit_call = permitted.empty? ? ".permit" : ".permit(#{permitted})"
        <<~RUBY
          class #{controller_class} < ApplicationController
            before_action :set_record, only: [:show, :edit, :update, :destroy]

            def index
              @records = #{model_class}.all
            end

            def show
            end

            def new
              @record = #{model_class}.new
            end

            def create
              @record = #{model_class}.new(record_params)
              if @record.save
                redirect_to "/#{table}/\#{@record.id}"
              else
                render :new, status: :unprocessable_entity
              end
            end

            def edit
            end

            def update
              if @record.update(record_params)
                redirect_to "/#{table}/\#{@record.id}"
              else
                render :edit, status: :unprocessable_entity
              end
            end

            def destroy
              @record.destroy
              redirect_to "/#{table}"
            end

            private

            def set_record
              @record = #{model_class}.find(params[:id])
            end

            def record_params
              params.require(:#{Reins.to_underscore(model_class)})#{permit_call}
            end
          end
        RUBY
      end

      def view_files
        {
          "app/views/#{table}/index.html.erb" => index_view,
          "app/views/#{table}/show.html.erb" => show_view,
          "app/views/#{table}/new.html.erb" => new_view,
          "app/views/#{table}/edit.html.erb" => edit_view,
          "app/views/#{table}/_form.html.erb" => form_partial
        }
      end

      def index_view
        rows = @fields.map { |n, _| "      <td><%= record.#{n} %></td>" }.join("\n")
        <<~ERB
          <h1>#{model_class.split(/(?=[A-Z])/).join(' ')}</h1>

          <table>
            <% @records.each do |record| %>
              <tr>
          #{rows}
              </tr>
            <% end %>
          </table>
        ERB
      end

      def show_view
        @fields.map { |n, _| "<p><strong>#{n}:</strong> <%= @record.#{n} %></p>" }.join("\n")
      end

      def new_view
        "<%= render \"form\", record: @record %>\n"
      end

      def edit_view
        "<%= render \"form\", record: @record %>\n"
      end

      def form_partial
        field_lines = @fields.map do |name, type|
          input = case type
                  when "text" then "<%= text_area :#{name}, value: record.#{name} %>"
                  else "<%= text_field :#{name}, value: record.#{name} %>"
                  end
          "  <div>\n    <%= label :#{name} %><br>\n    #{input}\n  </div>"
        end.join("\n")

        <<~ERB
          <%= form_with(url: "/#{table}", method: record.persisted? ? :put : :post) %>
          #{field_lines}
            <div><%= submit %></div>
          </form>
        ERB
      end

      def merged_routes_content
        return nil unless @fs.exist?(ROUTES_PATH)

        content = @fs.read(ROUTES_PATH)
        return content if content.include?("resources :#{table}")

        content.sub(/^end\b/m, "  resources :#{table}\nend")
      end

      def pluralize(str)
        if str.end_with?("y") && !str.end_with?("ay", "ey", "iy", "oy", "uy")
          "#{str[0..-2]}ies"
        else
          "#{str}s"
        end
      end
    end
  end
end
