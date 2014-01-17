module VtdXml

  class Document
    include_package 'com.ximpleware'
    include_package 'java.lang'
    include_package 'java.io'

    WITH_NAMESPACE_AWARE = true

    def initialize(contents)
      @generator = VTDGen.new
      @generator.doc = contents.to_s.to_java_bytes
      @generator.parse(WITH_NAMESPACE_AWARE)

      @navigator = @generator.nav
      @pilot = AutoPilot.new(@navigator)
      @modifier = XMLModifier.new(@navigator)


    rescue IllegalArgumentException, ParseException, EOFException => e
      raise ParseError, e.message
    end

    def xpath(*xpaths)
      namespaces = Hash === xpaths.last ? xpaths.pop : {}
      register_namespaces(namespaces)

      results = xpaths.map { |xpath| search(xpath) }
      results.flatten!
      results.compact!
      results

    rescue XPathParseException => e
      raise XPathError, '%s for xpath: %s' % [e.message, xpaths.inspect]
    ensure
      clear_xpath_namespaces
    end

    def register_namespaces(namespaces)
      namespaces.each do |prefix, url|
        @pilot.declare_xpath_name_space(prefix.to_s, url.to_s)
      end
    end

    def insert_after(xpath, xml, namespaces = {})
      register_namespaces(namespaces)
      @pilot.select_xpath(xpath)
      found = @pilot.eval_xpath() != -1
      @modifier.insert_after_element(xml) if found
      found
    rescue XPathParseException => e
      raise XPathError, e.message
    rescue Java::ComXimpleware::ModifyException => e
      raise ModifyError, e.message
    ensure
      @pilot.reset_xpath
      clear_xpath_namespaces
    end

    def select_node(xpath, namespaces={})
      register_namespaces(namespaces)
      @pilot.select_xpath(xpath)
      @navigator.to_raw_string(*offset_and_length_for(@navigator.element_fragment)) if @pilot.eval_xpath() != -1
    rescue XPathParseException => e
      raise XPathError, e.message
    rescue Java::ComXimpleware::ModifyException => e
      raise ModifyError, e.message
    ensure
      @pilot.reset_xpath
      clear_xpath_namespaces
    end

    def to_xml
      os = ByteArrayOutputStream.new(@modifier.get_updated_document_size)
      @modifier.output(os)
      os.to_string('UTF-8')
    end

    private

    def offset_and_length_for(fragment)
      return (fragment & 0b0000000000000000000000000000000011111111111111111111111111111111), (fragment >> 32)
    end

    def search(xpath)
      @pilot.select_xpath(xpath)

      results = []
      while (result = @pilot.eval_xpath()) != -1
        results << text_for(result)
      end
      results

    ensure
      @pilot.reset_xpath
    end

    # Beware of TCO!
    def text_for(index)
      if index != -1
        case @navigator.token_type(index)
          when VTDGen::TOKEN_STARTING_TAG #element node
            text_for(@navigator.text())
          when VTDGen::TOKEN_ATTR_NAME #attribute node
            text_for(@navigator.get_attr_val(@navigator.to_string(index)))
          when VTDGen::TOKEN_ATTR_VAL #attribute value
            @navigator.to_normalized_string(index)
          when VTDGen::TOKEN_CHARACTER_DATA #text node
            @navigator.to_normalized_string(index)
          when VTDGen::TOKEN_DOCUMENT #root node, don't think they can have text values
            @navigator.to_normalized_string(index)
        end
      end
    end

    def clear_xpath_namespaces
      begin
        @pilot.clear_xpath_name_spaces()
      rescue NullPointerException
      end
    end
  end
end

