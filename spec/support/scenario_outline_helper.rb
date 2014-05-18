require 'stringio'
require 'ostruct'

class ScenarioOutline
  attr_reader :examples

  def initialize(example_string)
    @example_string = example_string.gsub(/(^\n*)|(\s*\n*$)/,'')
    @examples = parse_example_string
  end

  private
  def parse_example_string
    example_string = StringIO.new(@example_string)
    header = parse_line(example_string.readline)
    example_lines = example_string.readlines
    parse_example_lines(header, example_lines)
  end

  def parse_line(line)
    line.lstrip.slice(1..line.length).chomp.split('|')
  end

  def parse_example_lines (header, example_lines)
    examples=[]
    example_lines.each do |example_line|
      examples << make_an_example(header, example_line)
    end
    examples
  end

  def make_an_example(header, example_line)
    newstruct = "{"
    parse_line(example_line).each_with_index do |example, index|
      newstruct += ":#{header[index].strip} => '#{example.strip}',"
    end
    OpenStruct.new(eval(newstruct.chop+"}"))
  end
end
