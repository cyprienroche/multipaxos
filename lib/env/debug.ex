
# distributed algorithms, n.dulay, 29 jan 2021
# coursework, paxos made moderately complex
#
# some helper functions for debugging

defmodule Debug do

def info(config, message, verbose \\ 1) do
  if config.debug_level >= verbose do IO.puts message end
end # log

def map(config, themap, verbose \\ 1) do
  if config.debug_level >= verbose do
    Enum.each(themap, fn ({key, value}) -> IO.puts "  #{key} #{inspect value}" end)
  end
end # map

def starting(config, verbose \\ 0) do
  if config.debug_level >= verbose do
    IO.puts "--> Starting #{config.node_name} at #{config.node_location}"
  end
end # starting

def letter(config, letter, verbose \\ 3) do
  if config.debug_level >= verbose do IO.write letter end
end # letter

def mapstring(map) do
  for {key, value} <- map, into: "" do "\n  #{key}\t #{inspect value}" end
end # mapstring

def module_info(config, message, _verbose \\ 1) do
  if Enum.member? config.debug_modules, config.module do
    IO.puts(config.log, message)
  end
end # client_info

def create_main_log_folder() do
  unless File.exists?('log') do
      File.mkdir!('log')
  end # unless
end # create_main_log_folder

def create_log_folder(config) do
  dir = "log/#{String.downcase(config.node_type)}#{config.node_num}"
  unless File.exists?(dir) do
      File.mkdir!(dir)
  end # unless
end # create_log_folder

def create_log_file(config) do
  dir = "log/#{String.downcase(config.node_type)}#{config.node_num}"
  name = '#{dir}/#{config.module}#{config.node_num}.txt'
  unless File.exists?(name) do
    Path.expand(name) |> File.write("", [:write])
  end # unless
  file = File.open!(name, [:utf8, :append])
  IO.puts(file, "#{config.module}#{config.node_num} log:\n")
 _config = Map.put config, :log, file
end

def special_log_file(config, count) do
# could use this function to create new log files for every commander and scout spawned
# count how many commanders were spawned and append the count to the name of the file
end

end # Debug
