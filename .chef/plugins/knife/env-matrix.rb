#
# Author:: Peter Schultz (<peter.schultz@classmarkets.com>)
# Copyright:: Copyright (c) 2013 classmarkets GmbH
#
## Licensed under the Apache License, Version 2.0 (the "License");
## you may not use this file except in compliance with the License.
## You may obtain a copy of the License at
##
##     http://www.apache.org/licenses/LICENSE-2.0
##
## Unless required by applicable law or agreed to in writing, software
## distributed under the License is distributed on an "AS IS" BASIS,
## WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
## See the License for the specific language governing permissions and
## limitations under the License.
##
#

module ClassmarketsKnifePlugins
  class EnvironmentMatrix < Chef::Knife

    banner "knife environment matrix [ENVIRONMENTS...]"

    def run
      environments = if name_args.size == 0
                       rest.get_rest("environments").keys
                     else
                       name_args
                     end

      books = {}
      book_names = []

      environments.each do |env_name|
        books[env_name] = get_env_cookbooks(env_name)
        books[env_name].each do |book_name|
        end
        book_names |= books[env_name].keys
      end

      book_names.sort!

      matrix = []

      book_names.each do |book_name|
        row = {}
        row[:book] = book_name
        row[:versions] = {}

        environments.each do |env_name|
          row[:versions][env_name] = {
            :version => get_cookbook_version(books[env_name][book_name])
          }
        end

        EnvironmentMatrix.count_updates(row)

        matrix << row
      end

      print_text matrix, environments
    end

    def text_colorize(emphasize, str)
      emphasize_colors = [
        [],
        [:yellow],
        ['rgb_ff4000'],
        [:red],
        [:magenta],
        [:bright_magenta],
      ]

      emphasize = [emphasize, emphasize_colors.length - 1].min

      ui.color(str, *emphasize_colors[emphasize])
    end

    def print_text(matrix, column_labels)

      min_column_width = 11

      index_column_label = "Cookbooks"
      column_widths = {}
      column_widths[:_index] = (matrix.map{ |row| row[:book].length } << index_column_label.length).max

      column_labels.each do |s|
        column_widths[s] = [ min_column_width, s.length ].max
      end

      row_format_string = "|  " + column_widths.map { |l, w| "%-#{w}s" }.join("  |  ") + "  |\n"

      ruler = sprintf *([row_format_string, '', column_labels.map { '' } ].flatten)
      ruler.gsub!(/\|/, '+')
      ruler.gsub!(/ /, '-')

      print ruler
      printf *([row_format_string, index_column_label, column_labels].flatten)
      print ruler

      matrix.each do |row|
        printf *([row_format_string, row[:book], row[:versions].map { |column_label, cell|
          column_width = column_widths[column_label]
          value = cell[:version] || ''

          colored = text_colorize(cell[:n_updates], value)
          (column_width - value.length).times { colored << " " }

          colored
        }].flatten)
      end

      print ruler
    end

    def get_env_cookbooks(env)
      rest.get_rest("environments/#{env}/cookbooks")
    end

    def get_cookbook_version(data)
      if data == nil || data['versions'].empty?
        'none'
      else
        data['versions'].first['version']
      end
    end

    def self.count_updates(row)
      n_updates = 0
      upstream = nil

      row[:versions].each do |field_name, cell|
        cell[:n_updates] = n_updates
        version = cell[:version]

        if version == 'none'
          cell[:n_updates] = if upstream == nil
                               0
                             else
                               n_updates + 1
                             end
          next
        end

        if upstream == nil
          upstream = Chef::VersionConstraint.new(">= #{version}")
          next
        end

        unless upstream.include?(version)
          n_updates += 1
          cell[:n_updates] = n_updates
        end

        upstream = Chef::VersionConstraint.new(">= #{version}")
      end

      return row
    end
  end
end
