#
# Additions to core Ruby objects
#

class String

  unless String.method_defined?(:camel_case)
    #
    # Turn an underscored string into camel case, ie this_becomes -> ThisBecomes
    #
    def camel_case
      self.split("_").inject("") { |str, piece| str + piece.capitalize }
    end
  end

  unless String.method_defined?(:to_class)
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
  end

  unless String.method_defined?(:classify)
    #
    # Turn a string in either underscore or camel case form into a class directly
    #
    def classify(mod = nil)
      self.camel_case.to_class(mod)
    end
  end

  unless String.method_defined?(:underscore)
    #
    # Turn a camelcase string into underscore string
    #
    def underscore
      self.split(/([A-Z][^A-Z]*)/).find_all { |str| str != "" }.join("_").downcase
    end
  end
end

