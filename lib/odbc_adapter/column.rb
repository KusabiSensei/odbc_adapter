module ODBCAdapter
  class Column < ActiveRecord::ConnectionAdapters::Column
    attr_reader :native_type

    def initialize(name, default, sql_type = nil, null = nil)
      @name             = name
      @sql_type         = sql_type
      @null             = null
      @limit            = extract_limit(sql_type)
      @precision        = extract_precision(sql_type)
      @scale            = extract_scale(sql_type)
      @type             = simplified_type(sql_type)
      @default          = extract_default(default)
      @default_function = nil
      @primary          = nil
      @coder            = nil

      if [ODBC::SQL_DECIMAL, ODBC::SQL_NUMERIC].include?(sql_type)
        set_numeric_params(scale, limit)
      end
    end

    # Returns the Ruby class that corresponds to the abstract data type.
    def klass
      case type
      when :integer                     then Fixnum
      when :float                       then Float
      when :decimal                     then BigDecimal
      when :datetime, :timestamp, :time then Time
      when :date                        then Date
      when :text, :string, :binary      then String
      when :boolean                     then Object
      end
    end

    def binary?
      type == :binary
    end

    # Casts value (which is a String) to an appropriate instance.
    def type_cast(value)
      return nil if value.nil?
      return coder.load(value) if encoded?

      klass = self.class

      case type
      when :string, :text        then value
      when :integer              then klass.value_to_integer(value)
      when :float                then value.to_f
      when :decimal              then klass.value_to_decimal(value)
      when :datetime, :timestamp then klass.string_to_time(value)
      when :time                 then klass.string_to_dummy_time(value)
      when :date                 then klass.value_to_date(value)
      when :binary               then klass.binary_to_string(value)
      when :boolean              then klass.value_to_boolean(value)
      else value
      end
    end

    private

    def extract_limit(sql_type)
      $1.to_i if sql_type =~ /\((.*)\)/
    end

    def extract_precision(sql_type)
      $2.to_i if sql_type =~ /^(numeric|decimal|number)\((\d+)(,\d+)?\)/i
    end

    def extract_scale(sql_type)
      case sql_type
      when /^(numeric|decimal|number)\((\d+)\)/i then 0
      when /^(numeric|decimal|number)\((\d+)(,(\d+))\)/i then $4.to_i
      end
    end

    def simplified_type(field_type)
      case field_type
      when /int/i
        :integer
      when /float|double/i
        :float
      when /decimal|numeric|number/i
        extract_scale(field_type) == 0 ? :integer : :decimal
      when /datetime/i
        :datetime
      when /timestamp/i
        :timestamp
      when /time/i
        :time
      when /date/i
        :date
      when /clob/i, /text/i
        :text
      when /blob/i, /binary/i
        :binary
      when /char/i
        :string
      when /boolean/i
        :boolean
      end
    end
  end
end
