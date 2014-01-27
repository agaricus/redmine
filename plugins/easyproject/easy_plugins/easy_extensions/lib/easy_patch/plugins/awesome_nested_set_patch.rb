module EasyPatch
  module AwesomeNestedSetInstanceMethodsPatch

    def self.included(base)
      base.class_eval do

        # Returns name of the current project with ancestors
        # Params:
        # :separator = string separator between parents and childs
        # :self_only = only self is returned
        # :name_method = method to get the name of an entity
        def family_name(options={})
          name_method = options[:name_method] || :name
          separator   = options[:separator]   || ' &#187; '
          prefix      = options[:prefix]      || '&nbsp;'

          s = if options[:self_only]
            (self.child? ? (prefix * 2 * (options[:level] || self.easy_level) + separator) : '') + self.send(name_method)
          else
            if self.child?
              ancestor_scope = self.self_and_ancestors
              ancestor_scope = ancestor_scope.select(options[:select]) if options[:select]
              ancestor_scope = ancestor_scope.joins(options[:joins]) if options[:joins]
              ancestor_scope = ancestor_scope.where(options[:where]) if options[:where]

              tree = ancestor_scope.all.collect do |e|
                if e.respond_to?(name_method)
                  e.send(name_method)
                else
                  e.name
                end
              end
              tree.join(separator)
            else
              self.send(name_method)
            end
          end
          s.html_safe
        end

        def easy_level
          result = read_attribute(:easy_level) if self.class.column_names.include?('easy_level')
          result ||= self.level

          result
        end

      end
    end
  end

  module AwesomeNestedSetClassMethodsPatch

    def self.included(base)
      base.class_eval do

        def each_with_easy_level(objects, options={}, &block)
          level_diff = options[:zero_start] ? objects.first.easy_level : 0
          objects.each do |o|
            yield(o, o.easy_level - level_diff)
          end
        end

        def each_with_level(objects, with_ancestors = false, &block)
          path = [nil]
          objects.each do |o|
            if o.parent_id != path.last
              # we are on a new level, did we decent or ascent?
              if path.include?(o.parent_id)
                # remove wrong wrong tailing paths elements
                path.pop while path.last != o.parent_id
              else
                path << o.parent_id
              end
            end
            if with_ancestors
              yield(o, path.length - 1, path.compact)
            else
              yield(o, path.length - 1)
            end
          end
        end

      end
    end

  end
end
EasyExtensions::PatchManager.register_redmine_plugin_patch 'CollectiveIdea::Acts::NestedSet::Model', 'EasyPatch::AwesomeNestedSetInstanceMethodsPatch'
EasyExtensions::PatchManager.register_redmine_plugin_patch 'CollectiveIdea::Acts::NestedSet::Model::ClassMethods', 'EasyPatch::AwesomeNestedSetClassMethodsPatch'
