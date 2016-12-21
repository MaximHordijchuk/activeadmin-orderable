module ActiveRecord
  module ActsAs
    module Ordinal
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        attr_reader :ordinal_field

        def acts_as_ordinal(options = {})
          @ordinal_field = options[:ordinal_field] || :ordinal

          class_eval do
            include ActiveRecord::ActsAs::Ordinal::InstanceMethods
          end
        end
      end

      module InstanceMethods
        def insert_at(position, ordinals_scope = nil)
          return if position == ordinal # if ordinal haven't changed

          # if new position is not occupied just take this ordinal
          unless self.class.find_by("#{acts_ordinal_field}": position)
            update("#{acts_ordinal_field}": position)
            return
          end

          items = items_scoped(position, ordinals_scope)
          current_positions = items.map { |item| item.send(acts_ordinal_field) }
          reordered_positions = reorder_positions(position, current_positions)
          update_ordinals(items, reordered_positions)
        end

        def acts_ordinal_field
          self.class.ordinal_field
        end

        def acts_ordinal_value
          self.send(acts_ordinal_field)
        end

        private

        def ordinal_range(position)
          position > acts_ordinal_value ? (acts_ordinal_value + 1)..position : position...acts_ordinal_value
        end

        def items_scoped(position, ordinals_scope)
          actual_ordinals_scope = *ordinal_range(position)
          actual_ordinals_scope &= ordinals_scope if ordinals_scope
          self.class.where("#{acts_ordinal_field}": actual_ordinals_scope).order(acts_ordinal_field).to_a.push(self)
        end

        def reorder_positions(position, positions)
          position > acts_ordinal_value ? positions.rotate(-1) : positions.rotate
        end

        def update_ordinals(items, positions)
          items.each_with_index { |item, index| item.update("#{acts_ordinal_field}": positions[index]) }
        end
      end
    end
  end
end
