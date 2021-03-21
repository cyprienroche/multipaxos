
# helper functions for debugging

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

# -- folder functions --

def create_folder(dir) do
  unless File.exists?(dir) do
      File.mkdir!(dir)
  end # unless
end # create_folder

def create_main_log_folder(), do: create_folder('log')

def create_log_folder(config, node_type) do
  dir = "log/#{String.downcase(config.node_type)}#{config.node_num}"
  create_folder(dir)
  if (node_type == :server) do
    create_folder("#{dir}/commander#{config.node_num}")
    create_folder("#{dir}/scout#{config.node_num}")
  end # if
end # create_log_folder

# -- file functions --

defp create_log_file(config, dir, module_name) do
  if Enum.member? config.debug_modules, config.module do
    file_name = '#{dir}/#{module_name}.txt'
    unless File.exists?(file_name) do
      Path.expand(file_name) |> File.write("", [:write])
    end # unless
    file = File.open!(file_name, [:utf8, :append])
    IO.puts(file, "#{module_name} log:\n")
   _config = Map.put config, :log, file
  else
    config
  end
end # create_log_file

def create_module_log_file(config, name_extension) do
  # used for commander and scout
  name = '#{config.module}#{config.node_num}'
  dir = "log/#{String.downcase(config.node_type)}#{config.node_num}"
  _config = create_log_file(config, "#{dir}/#{name}", "#{name}_#{name_extension}")
end # create_module_log_file

def create_module_log_file(config) do
  # used for client, replica, leader, and acceptor
  name = '#{config.module}#{config.node_num}'
  dir = "log/#{String.downcase(config.node_type)}#{config.node_num}"
  _config = create_log_file(config, dir, name)
end # create_module_log_file

end # Debug
