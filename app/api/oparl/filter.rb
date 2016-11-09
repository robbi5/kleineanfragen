#
# Filter modeled after OParl Spec.
#
module OParl
  module Filter
    def self.included(base)
      base.class_eval do
        helpers do
          def filter(collection)
            a = collection.arel_table
            collection = collection.where(a[:created_at].gt(params[:created_since])) unless params[:created_since].nil?
            collection = collection.where(a[:created_at].lt(params[:created_until])) unless params[:created_until].nil?
            collection = collection.where(a[:updated_at].gt(params[:modified_since])) unless params[:modified_since].nil?
            collection = collection.where(a[:updated_at].lt(params[:modified_until])) unless params[:modified_until].nil?
            collection
          end
        end

        def self.filter(options = {})
          params do
            optional :created_since,  type: DateTime
            optional :created_until,  type: DateTime
            optional :modified_since, type: DateTime
            optional :modified_until, type: DateTime
          end
        end
      end
    end
  end
end