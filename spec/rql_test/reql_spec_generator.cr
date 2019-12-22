require "yaml"

def yaml_fixes(str)
  str = str.gsub("\\", "\\\\")
  str = str.gsub(/(\w+): (.+)\n/) do
    var = $1
    value = $2
    "#{var}: \"#{value.gsub("\"", "\\\"")}\"\n"
  end
  str
end

def quotes_fixes(str)
  str = str.gsub(/'([^']*)'/) { "\"#{$1.gsub("\"", "\\\"")}\"" }
  str
end

def language_fixes(str)
  lang_replaces = {
    "None"  => "nil",
    "null"  => "nil",
    "True"  => "true",
    "False" => "false",
  }
  regex = /([^"'\w]|^)(#{lang_replaces.keys.join("|")})([^"'\w]|$)/
  str = str.gsub(regex) do
    "#{$1}#{lang_replaces[$2]}#{$3}"
  end
  str = quotes_fixes(str)
  str = str.gsub(".force_encoding(\"BINARY\")", ".to_slice")
  str = str.gsub("[]", "[] of Int32")
  str = str.gsub(/([\(,<>=]\s*)\{\}/) { "#{$1}{} of String => Int32" }
  str = str.gsub(/^\{\}/) { "{} of String => Int32" }
  str = str.gsub(/([^\\\d])\":/) { "#{$1}\" => " }
  str = str.gsub(/(\s|\{|,)(\d+):/) { "#{$1}#{$2} => " }
  str = str.gsub(/(\}):/) { "#{$1} => " }
  str = str.gsub(/(\W\s|\{|,|\()(\w+):/) { "#{$1}#{$2}: " }
  str = str.gsub("nil:", "nil =>")
  str = str.gsub("{{", "{ {")
  str = str.gsub("orderby", "order_by")
  str = str.gsub(/:(\w+) =>/) { "#{$1}:" }
  str
end

data = YAML.parse(yaml_fixes File.read(ARGV[0]))

puts "describe #{(ARGV[0] + ": ").inspect} do"
puts "describe #{data["desc"].inspect} do"
if tables = data["table_variable_name"]?
  puts
  tables.as_s.split(", ").map(&.split(" ")).flatten.each_with_index do |tablevar, i|
    random_name = "test_#{Time.now.to_unix}_#{rand(10000)}_#{i + 1}"
    puts "  r.db(\"test\").table_create(#{random_name.inspect}).run(conn)"
    puts "  #{tablevar} = r.db(\"test\").table(#{random_name.inspect})"
  end
end
data["tests"].as_a.each_with_index do |test, i|
  if d = test["def"]?
    if d.raw.is_a? Hash
      code = (d["rb"]? || d["cd"]).as_s
      code = d["js"].as_s if d["js"]? && d["js"].as_s =~ /\* 1000/
    else
      code = d.as_s
    end
    puts "  #{language_fixes code}"
  elsif test["ot"]? == nil && (test["rb"]? || test["cd"]?)
    assign = (language_fixes (test["rb"]? || test["cd"]).as_s).split("=")
    var = assign[0].strip
    value = assign[1].strip
    puts "  #{var} = #{value}.run(conn).datum.int32"
  else
    test["ot"]?
    subtests = test["rb"]? || test["cd"]?
    next unless subtests
    next if subtests == ""
    subtests = subtests.raw.is_a?(Array) ? subtests.as_a.map &.as_s : subtests.raw.is_a?(String) ? [subtests.as_s] : [] of String

    output = test["ot"]
    unless output.raw.is_a? String
      if output["js"]? && output["js"].as_s =~ /reduction/
        output = output["js"]
      else
        output = output["rb"]? || output["cd"]
      end
    end
    output = quotes_fixes output.as_s

    runopts = if test["runopts"]?
                String.build do |io|
                  io << ", {"
                  test["runopts"].raw.as(Hash).each do |(k, v)|
                    io << k.inspect << " => " << v
                    io << ","
                  end
                  io << "}"
                end
              else
                ""
              end

    puts unless i == 0
    subtests.each_with_index do |subtest, j|
      next if output =~ /lambda/ || subtest =~ /lambda/
      subtest = language_fixes subtest
      puts unless j == 0
      test_id = "##{i + 1}.#{j + 1}"
      puts "  #{ARGV.includes?(test_id) ? "pending" : "it"} \"passes on test #{test_id}: #{subtest.gsub("\\", "\\\\").gsub("\"", "\\\"")}\" do"
      if output =~ /err\("(\w+)",\s?"(.+?)"[,)]/
        err = $1.gsub("Reql", "ReQL::")
        puts "    expect_raises(#{err}, \"#{$2.gsub("\\\\", "\\")}\") do"
        puts "      (#{subtest}).run(conn#{runopts}).datum"
        puts "    end"
      elsif output =~ /err_regex\("(\w+)",\s?"(.+?)"[,)]/
        err = $1.gsub("Reql", "ReQL::")
        puts "    expect_raises(#{err}, /#{$2.gsub("\\\\", "\\")}/) do"
        puts "      (#{subtest}).run(conn#{runopts}).datum"
        puts "    end"
      else
        puts "    result = (#{subtest}).run(conn#{runopts}).datum"
        puts "    match_reql_output(result) { (#{language_fixes output}) }"
      end
      puts "  end"
    end
  end
end
puts "end"
puts "end"
