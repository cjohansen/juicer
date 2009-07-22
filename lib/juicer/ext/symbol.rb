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
