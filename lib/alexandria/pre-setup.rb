# Stolen from rbbr's code, by Masao Mutoh.

File.open('config.rb', 'w') do |file|
    file.print <<EOF
# This file is automatically generated by the installer.
# Do not edit by hands.

module Alexandria
    module Config
        DATA_DIR = '#{config('data-dir')}/alexandria'
        LIB_DIR = '#{config('rb-dir')}'
    end
end
EOF
end
