require "fileutils"
require "reins/generators/model_generator"

module Reins
  module Generators
    class ScaffoldGenerator
      def initialize(name, fields = [])
        @name = name
        @fields = fields.map { |f| f.split(":", 2) }
      end

      def run
        ModelGenerator.new(@name, @fields.map { |n, t| "#{n}:#{t}" }).run
        write_controller
        write_views
        write_form_partial
        append_resources_route
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

      def write_controller
        path = "app/controllers/#{table}_controller.rb"
        FileUtils.mkdir_p(File.dirname(path))
        File.write(path, controller_content)
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

      def write_views
        FileUtils.mkdir_p("app/views/#{table}")
        File.write("app/views/#{table}/index.html.erb", index_view)
        File.write("app/views/#{table}/show.html.erb",  show_view)
        File.write("app/views/#{table}/new.html.erb",   new_view)
        File.write("app/views/#{table}/edit.html.erb",  edit_view)
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

      def write_form_partial
        File.write("app/views/#{table}/_form.html.erb", form_partial)
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

      def append_resources_route
        path = "config/routes.rb"
        return unless File.exist?(path)

        content = File.read(path)
        return if content.include?("resources :#{table}")

        new_content = content.sub(/^end\b/m, "  resources :#{table}\nend")
        File.write(path, new_content)
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
