# Requiring with this pattern to mirror ActiveRecord
require 'active_record/connection_adapters/odbc_adapter'

module ODBCAdapter
  class << self
    def dbms_registry
      @dbms_registry ||= {
        /my.*sql/i => :MySQL,
        /postgres/i => :PostgreSQL,
        /snowflake/i => :Snowflake
      }
    end

    def register(pattern, superclass, &block)
      dbms_registry[pattern] = Class.new(superclass, &block)
    end
  end
end
