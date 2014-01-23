require_relative '../../test_load_paths'
require 'vtd_xml'

module VtdXml
  class DocumentTest < Test::Unit::TestCase

    context 'adversarial cases' do
      setup do
        xml = <<-EOF
<?xml version="1.0" encoding="UTF-8"?>
<boo:root xmlns:boo="boo.com">
the contents
</boo:root>
        EOF

        @document = Document.new(xml)
      end

      should 'error when using namespaces that are not registered' do
        unregistered = 'notreal'
        e = assert_raise(XPathError) do
          @document.xpath("//#{unregistered}:*")
        end

        assert_match(%r{No URL found for prefix:#{unregistered}}, e.message)
      end

      should 'not persist namespaces between xpath searches' do
        xpath = '//boo:root'
        @document.xpath(xpath, {'boo' => 'boo.com'})
        e = assert_raise(XPathError) do
          @document.xpath(xpath)
        end

        assert_match(%r{No URL found for prefix:boo}, e.message)
      end

      should 'error on invalid xml' do
        e = assert_raise(ParseError) do
          @document = Document.new('<?xml version="1.0" encoding="UTF-8"?><boo</boo>')
        end
        assert_match('Starting tag Error', e.message)

        e = assert_raise(ParseError) do
          @document = Document.new('<?xml version="1.0" encoding="UTF-8"?><boo><//boo>')
        end
        assert_match('Ending tag error', e.message)

        e = assert_raise(ParseError) do
          @document = Document.new('<?xml version="1.0" encoding="UTF-8"?><boo>')
        end
        assert_match('XML document incomplete', e.message)

        e = assert_raise(ParseError) do
          @document = Document.new('<?xml version="1.0" encoding="UTF-8"?><boo><bam></boo>')
        end
        assert_match('Start/ending tag mismatch', e.message)
      end

      should 'parse xml without qualified namespaces' do
        @document = Document.new('<?xml version="1.0" encoding="UTF-8"?><boo>dsds</boo>')
        assert_equal(%w(dsds), @document.xpath('/boo'))
      end

      should 'fail when contents are not provided' do
        assert_raise ParseError do
          Document.new(nil)
        end

        assert_raise ParseError do
          Document.new('')
        end

        assert_raise ParseError do
          Document.new(' ')
        end
      end
    end

    context 'success cases' do
      setup do
        xml = <<-EOF
<?xml version="1.0" encoding="UTF-8"?>
<boo:root xmlns:boo="boo.com">
  the contents
  <boo:bam boo:zing="blamo">
    right in the kisser
  </boo:bam>
  other contents
</boo:root>
        EOF
        @namespaces = {boo: 'boo.com'}
        @document = Document.new(xml)
      end

      should 'extract string from root' do
        assert_equal([''], @document.xpath('/', @namespaces))
      end

      should 'extract text from child text nodes' do
        assert_equal(['the contents'], @document.xpath('/boo:root', @namespaces))
        assert_equal(['the contents', 'other contents'], @document.xpath('/boo:root/text()', @namespaces))
      end

      should 'extract string from element node containing only text' do
        assert_equal(['right in the kisser'], @document.xpath('/boo:root/boo:bam', @namespaces))
        assert_equal(['right in the kisser'], @document.xpath('/boo:root/boo:bam/text()', @namespaces))
      end

      should 'extract string from attribute node' do
        assert_equal(['blamo'], @document.xpath('/boo:root/boo:bam/@boo:zing', @namespaces))
      end

      should 'extract multiple strings from multiple xpaths' do
        assert_equal(['blamo', 'the contents'], @document.xpath('/boo:root/boo:bam/@boo:zing', '/boo:root', @namespaces))
      end

    end

    context 'add XML sibling node' do
      setup do
        xml = <<-EOF
<?xml version="1.0" encoding="UTF-8"?>
<boo:root xmlns:boo="boo.com">
  the contents
  <boo:bam boo:zing="blamo">
    right in the kisser
  </boo:bam>
  other contents
  <boo:sam>I am</boo:sam>
</boo:root>
        EOF
        @namespaces = {boo: 'boo.com'}
        @document = Document.new(xml)
      end

      should 'return false if xpath to insert after was not found' do
        added_xml = '<boo:p>faa</boo:p>'
        refute(@document.insert_after('/boo:root/boo:nothing', added_xml, @namespaces), 'insert_after should return false')
      end

      should 'add an XML node after valid xpath' do
        added_xml = "\n  <boo:bang>the big bang</boo:bang>"
        assert(@document.insert_after('/boo:root/boo:bam', added_xml, @namespaces), 'insert_after should return true')
        modified_document = Document.new(@document.to_xml)
        assert_equal(['the big bang'], modified_document.xpath('/boo:root/boo:bang', @namespaces))
        assert_equal(['right in the kisser'], modified_document.xpath('/boo:root/boo:bang/preceding-sibling::boo:bam', @namespaces))

        expected_xml = <<-EOF
<?xml version="1.0" encoding="UTF-8"?>
<boo:root xmlns:boo="boo.com">
  the contents
  <boo:bam boo:zing="blamo">
    right in the kisser
  </boo:bam>
  <boo:bang>the big bang</boo:bang>
  other contents
  <boo:sam>I am</boo:sam>
</boo:root>
        EOF
        assert_equal(expected_xml, @document.to_xml)
      end

      should 'demonstrate you can insert after the root node producing an invalid XML document' do
        @document.insert_after('/boo:root', '<boo:bang>the big bang</boo:bang>', @namespaces)
        assert_raises ParseError do
          Document.new(@document.to_xml)
        end
      end

      should 'demonstrate you can insert invalid XML that will not parse properly' do
        @document.insert_after('/boo:root', '<boo:bang>the big bang', @namespaces)
        assert_raises ParseError do
          Document.new(@document.to_xml)
        end
      end

      should 'be able to insert several XML nodes' do
        added_xml = "\n  <boo:bang>the big bang</boo:bang>"
        more_xml = "\n  <boo:zoo>zoom</boo:zoo>"
        @document.insert_after('/boo:root/boo:bam', added_xml, @namespaces)
        @document.insert_after('/boo:root/boo:sam', more_xml, @namespaces)

        expected_xml = <<-EOF
<?xml version="1.0" encoding="UTF-8"?>
<boo:root xmlns:boo="boo.com">
  the contents
  <boo:bam boo:zing="blamo">
    right in the kisser
  </boo:bam>
  <boo:bang>the big bang</boo:bang>
  other contents
  <boo:sam>I am</boo:sam>
  <boo:zoo>zoom</boo:zoo>
</boo:root>
        EOF
        assert_equal(expected_xml, @document.to_xml)
      end

      should 'fail to insert using xpath of a newly inserted node' do
        added_xml = "\n  <boo:bang>the big bang</boo:bang>"
        more_xml = "\n  <boo:zoo>zoom</boo:zoo>"
        @document.insert_after('/boo:root/boo:bam', added_xml, @namespaces)
        assert(!@document.insert_after('/boo:root/boo:bang', more_xml, @namespaces))

        expected_xml = <<-EOF
<?xml version="1.0" encoding="UTF-8"?>
<boo:root xmlns:boo="boo.com">
  the contents
  <boo:bam boo:zing="blamo">
    right in the kisser
  </boo:bam>
  <boo:bang>the big bang</boo:bang>
  other contents
  <boo:sam>I am</boo:sam>
</boo:root>
        EOF
        assert_equal(expected_xml, @document.to_xml)
      end

      should 'raise an exception when inserting after the same node' do
        added_xml = "\n  <boo:bang>the big bang</boo:bang>"
        more_xml = "\n  <boo:zoo>zoom</boo:zoo>"
        @document.insert_after('/boo:root/boo:bam', added_xml, @namespaces)
        e = assert_raise(ModifyError) do
          @document.insert_after('/boo:root/boo:bam', more_xml, @namespaces)
        end
        assert_equal('There can be only one insert per offset', e.message)
      end

      should 'not persist namespaces from insert_after' do
        xpath = '//boo:root/boo:bam'
        @document.insert_after(xpath, '<boo:b>bold</boo:b>', {'boo' => 'boo.com'})
        e = assert_raise(XPathError) do
          @document.insert_after('//boo:root/boo:sam', '<p>para</p>')
        end

        assert_equal('No URL found for prefix:boo', e.message)
      end
    end

    context 'adding a child node' do
      setup do
        @xml = <<-EOF
<?xml version="1.0" encoding="UTF-8"?>
<boo:root xmlns:boo="boo.com">
  the contents
  <boo:bam boo:zing="blamo">
  </boo:bam>
  <boo:biz/>
  other contents
  <boo:sam>I am</boo:sam>
</boo:root>
        EOF
        @namespaces = {boo: 'boo.com'}
        @document = Document.new(@xml)
      end

      should 'insert under a specified xpath when nodes exist' do
        xpath = '//boo:root'
        @document.add_child(xpath, "  <boo:wow>That's got to hurt</boo:wow>\n", @namespaces)

        expected_xml = <<-EOF
<?xml version="1.0" encoding="UTF-8"?>
<boo:root xmlns:boo="boo.com">
  the contents
  <boo:bam boo:zing="blamo">
  </boo:bam>
  <boo:biz/>
  other contents
  <boo:sam>I am</boo:sam>
  <boo:wow>That's got to hurt</boo:wow>
</boo:root>
EOF
        assert_equal(expected_xml, @document.to_xml)
      end

      should 'insert a child node under specified xpath when only text exist' do
        xpath = '//boo:sam'
        @document.add_child(xpath, "<boo:wow>That's got to hurt</boo:wow>\n  ", @namespaces)

        expected_xml = <<-EOF
<?xml version="1.0" encoding="UTF-8"?>
<boo:root xmlns:boo="boo.com">
  the contents
  <boo:bam boo:zing="blamo">
  </boo:bam>
  <boo:biz/>
  other contents
  <boo:sam>I am<boo:wow>That's got to hurt</boo:wow>
  </boo:sam>
</boo:root>
EOF
        assert_equal(expected_xml, @document.to_xml)
      end

      should 'insert a child node under specified xpath when no nodes exist' do
        xpath = '//boo:bam[@boo:zing="blamo"]'
        @document.add_child(xpath, "  <boo:wow>That's got to hurt</boo:wow>\n  ", @namespaces)

        expected_xml = <<-EOF
<?xml version="1.0" encoding="UTF-8"?>
<boo:root xmlns:boo="boo.com">
  the contents
  <boo:bam boo:zing="blamo">
    <boo:wow>That's got to hurt</boo:wow>
  </boo:bam>
  <boo:biz/>
  other contents
  <boo:sam>I am</boo:sam>
</boo:root>
EOF
        assert_equal(expected_xml, @document.to_xml)
      end

      should 'insert a child node under specified xpath when no interior exists' do
        xpath = '//boo:biz'
        @document.add_child(xpath, "\n    <boo:wow>That's got to hurt</boo:wow>\n  ", @namespaces)

        expected_xml = <<-EOF
<?xml version="1.0" encoding="UTF-8"?>
<boo:root xmlns:boo="boo.com">
  the contents
  <boo:bam boo:zing="blamo">
  </boo:bam>
  <boo:biz>
    <boo:wow>That's got to hurt</boo:wow>
  </boo:biz>
  other contents
  <boo:sam>I am</boo:sam>
</boo:root>
EOF
        assert_equal(expected_xml, @document.to_xml)
      end

      should 'insert under a non_existant xpath' do
        xpath = '//boo:not_an_xpath_waaaaaagh'
        refute(@document.add_child(xpath, "\n    <boo:wow>That's got to hurt</boo:wow>\n  ", @namespaces))
        assert_equal(@xml, @document.to_xml)
      end
    end

    context 'select raw xml' do

      setup do
        xml = <<-EOF
<?xml version="1.0" encoding="UTF-8"?>
<boo:root xmlns:boo="boo.com" xmlns:zang="zang.com">
  <boo:bam zang:zing="blamo" />
  <boo:target />
</boo:root>
        EOF
        @namespaces = {boo: 'boo.com'}
        @document = Document.new(xml)
      end

      should 'provide raw XML for a given node' do
        node_xml = @document.select_node('//boo:bam', @namespaces)

        expected_xml = '<boo:bam zang:zing="blamo" />'
        assert_equal(expected_xml, node_xml)
      end
    end

  end
end

