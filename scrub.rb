require 'json'
sensitive_fields_arg = ARGV[0]
input_arg = ARGV[1]

test_name = input_arg.split("/")[-2]
SENSITIVE_FIELDS = File.read(sensitive_fields_arg).split
input = JSON.parse(File.read(input_arg))

def scrub(field, parent_key: nil)
	case field
	when String, Numeric
		field.to_s.gsub(/[[:alnum:]]/, "*")
	when TrueClass, FalseClass
		"-"
	when Array
		field.map { |f| scrub(f) }
	when Hash
		field.keys.each do |k|
			if (parent_key && SENSITIVE_FIELDS.include?(parent_key)) || SENSITIVE_FIELDS.include?(k) || field[k].is_a?(Hash)
				field[k] = scrub(field[k], parent_key: k)
			end
		end
		field
	end
end

scrub(input)

expected_output = JSON.parse(File.read("./tests/#{test_name}/output.json"))
if expected_output == input
	p "Scrub Completed (#{test_name}). Find results in /generated_output/#{test_name}.json"
	File.write("./generated_output/#{test_name}.json", JSON.pretty_generate(input))
else
	p "Scrub Incompleted (#{test_name})"
	p input
end


