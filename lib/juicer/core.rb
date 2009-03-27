#
# Additions to core Ruby objects
#

class String
  #
  # Turn an underscored string into camel case, ie this_becomes -> ThisBecomes
  #
  def camel_case
    self.split("_").inject("") { |str, piece| str + piece.capitalize }
  end

  #
  # Treat a string as a class name and return the class. Optionally provide a
  # module to look up the class in.
  #
  def to_class(mod = nil)
    res = "#{mod}::#{self}".sub(/^::/, "").split("::").inject(Object) do |mod, obj|
      raise "No such class/module" unless mod.const_defined?(obj)
      mod = mod.const_get(obj)
    end
  end

  #
  # Turn a string in either underscore or camel case form into a class directly
  #
  def classify(mod = nil)
    self.camel_case.to_class(mod)
  end

  #
  # Turn a camelcase string into underscore string
  #
  unless String.method_defined?(:underscore)
    def underscore
      self.split(/([A-Z][^A-Z]*)/).find_all { |str| str != "" }.join("_").downcase
    end
  end
end

class Symbol
  #
  # Converts symbol to string and calls String#camel_case
  #
  def camel_case
    self.to_s.camel_case
  end

  #
  # Converts symbol to string and calls String#classify
  #
  def classify(mod = nil)
    self.to_s.classify(mod)
  end
end

class Logger
  def format_message(severity, datetime, progname, msg)
    "#{msg}\n"
  end
end
