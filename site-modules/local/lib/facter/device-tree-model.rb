Facter.add(:model) do
  confine :kernel => 'Linux'
  setcode do
    if File.exist? '/proc/device-tree/model'
      model = Facter::Core::Execution.execute('cat /proc/device-tree/model')
      model.sub(/\u0000/,'')
    end
  end
end
