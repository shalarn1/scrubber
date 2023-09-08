require 'json'

sensitive_fields_arg = ARGV[0]
input_arg = ARGV[1]

SENSITIVE_FIELDS = File.read(sensitive_fields_arg).split
test_name = input_arg.split("/")[-2]
input = JSON.parse(File.read(input_arg))

# This method must initially be called with a valid json
def scrub(data, parent_key:)
	case data
	when String, Numeric, TrueClass, FalseClass
		# scrub basic data types if its nested under a sensitive parent key
		if parent_key && SENSITIVE_FIELDS.include?(parent_key)
			if data.is_a?(TrueClass) || data.is_a?(FalseClass) 
				"-"
			else
				replace_alphanumeric(data.to_s)
			end
		else
			data
		end
 	when Array
		data.map { |f| scrub(f, parent_key: parent_key) }
	when Hash
		# Scrub the data if 
		# 1) Its a nested data type
		# 2) Its parent is a sensitive key
		# 3) Its parent is not a sensitive key but the current key itself is sensitive
		data.keys.each do |k|
			if data[k].is_a?(Hash) || data[k].is_a?(Array) || (parent_key && SENSITIVE_FIELDS.include?(parent_key)) || SENSITIVE_FIELDS.include?(k)
				key = (parent_key && SENSITIVE_FIELDS.include?(parent_key)) ? parent_key : k
				data[k] = scrub(data[k], parent_key: key)
			end
		end
		data
	when nil
		data
	end
end

def replace_alphanumeric(str)
	str_arr = str.split('')
 	str_arr.each_with_index do |c, i|
 		str_arr[i] = "*" if c.match?(/[[:alnum:]]/)
 	end
 	str_arr.join
end

scrub(input, parent_key: nil)

expected_output = JSON.parse(File.read("./tests/#{test_name}/output.json"))
if expected_output == input
	p "Scrub Completed (#{test_name}). Find results in /generated_output/manual/#{test_name}.json"
	File.write("./generated_output/manual/#{test_name}.json", JSON.pretty_generate(input))
else
	p "Scrub Incompleted (#{test_name})"
	p input
end