require File.join(File.dirname(__FILE__), '..', 'vcsrepo')

Puppet::Type.type(:vcsrepo).provide(:p4, :parent => Puppet::Provider::Vcsrepo) do
  desc "Supports Perforce depots"

  has_features :filesystem_types, :reference_tracking, :p4config

  def create
    check_force
    # create or update client
    create_client(client_name)

    # if source provided, sync client
    source = @resource.value(:source)
    if source
      revision = @resource.value(:revision)
      sync_client(source, revision)
    end

    update_owner
  end

  def working_copy_exists?
    # Check if the server is there, or raise error
    p4(['info'], {:marshal => false})

    # Check if workspace is setup
    args = ['where']
    args.push(@resource.value(:path) + "/...")
    hash = p4(args, {:raise => false})

    return (hash['code'] != "error")
  end

  def exists?
    working_copy_exists?
  end

  def destroy
    args = ['client']
    args.push('-d', '-f')
    args.push(client_name)
    p4(args)
    FileUtils.rm_rf(@resource.value(:path))
  end

  def latest?
    rev = self.revision
    if rev
      (rev >= self.latest)
    else
      true
    end
  end

  def latest
    args = ['changes']
    args.push('-m1', @resource.value(:source))
    hash = p4(args)

    return hash['change'].to_i
  end

  def revision
    args = ['cstat']
    args.push(@resource.value(:source))
    hash = p4(args, {:marshal => false})
    hash = marshal_cstat(hash)

    revision = 0
    if hash && hash['code'] != 'error'
      hash['data'].each do |c|
        if c['status'] == 'have'
          change = c['change'].to_i
          revision = change if change > revision
        end
      end
    end
    return revision
  end

  def revision=(desired)
    sync_client(@resource.value(:source), desired)
    update_owner
  end

  def source
    args = ['where']
    args.push(@resource.value(:path) + "/...")
    hash = p4(args, {:raise => false})

    return hash['depotFile']
  end

  def source=(desired)
    create # recreate
  end

  private

  def update_owner
    if @resource.value(:owner) or @resource.value(:group)
      set_ownership
    end
  end

  # Sync the client workspace files to head or specified revision.
  # Params:
  # +source+:: Depot path to sync
  # +revision+:: Perforce change list to sync to (optional)
  def sync_client(source, revision)
    Puppet.debug "Syncing: #{source}"
    args = ['sync']
    if revision
      args.push(source + "@#{revision}")
    else
      args.push(source)
    end
    p4(args)
  end

  # Returns the name of the Perforce client workspace
  def client_name
    p4config = @resource.value(:p4config)

    # default (generated) client name
    path = @resource.value(:path)
    host = Facter.value('hostname')
    default = "puppet-" + Digest::MD5.hexdigest(path + host)

    # check config for client name
    set_client = nil
    if p4config && File.file?(p4config)
      open(p4config) do |f|
        m = f.grep(/^P4CLIENT=/).pop
        p = /^P4CLIENT=(.*)$/
        set_client = p.match(m)[1] if m
      end
    end

    return set_client || ENV['P4CLIENT'] || default
  end

  # Create (or update) a client workspace spec.
  # If a client name is not provided then a hash based on the path is used.
  # Params:
  # +client+:: Name of client workspace
  # +path+:: The Root location of the Perforce client workspace
  def create_client(client)
    Puppet.debug "Creating client: #{client}"

    # fetch client spec
    hash = parse_client(client)
    hash['Root'] = @resource.value(:path)
    hash['Description'] = "Generated by Puppet VCSrepo"

    # check is source is a Stream
    source = @resource.value(:source)
    if source
      parts = source.split(/\//)
      if parts && parts.length >= 4
        source = "//" + parts[2] + "/" + parts[3]
        streams = p4(['streams', source], {:raise => false})
        if streams['code'] == "stat"
          hash['Stream'] = streams['Stream']
          notice "Streams" + streams['Stream'].inspect
        end
      end
    end

    # save client spec
    save_client(hash)
  end


  # Fetches a client workspace spec from Perforce and returns a hash map representation.
  # Params:
  # +client+:: name of the client workspace
  def parse_client(client)
    args = ['client']
    args.push('-o', client)
    hash = p4(args)

    return hash
  end


  # Saves the client workspace spec from the given hash
  # Params:
  # +hash+:: hash map of client spec
  def save_client(hash)
    spec = String.new
    view = "\nView:\n"

    hash.keys.sort.each do |k|
      v = hash[k]
      next if( k == "code" )
      if(k.to_s =~ /View/ )
        view += "\t#{v}\n"
      else
        spec += "#{k.to_s}: #{v.to_s}\n"
      end
    end
    spec += view

    args = ['client']
    args.push('-i')
    p4(args, {:input => spec, :marshal => false})
  end

  # Sets Perforce Configuration environment.
  # P4CLIENT generated, but overwitten if defined in config.
  def config
    p4config = @resource.value(:p4config)

    cfg = Hash.new
    cfg.store 'P4CONFIG', p4config if p4config
    cfg.store 'P4CLIENT', client_name
    return cfg
  end

  def p4(args, options = {})
    # Merge custom options with defaults
    opts = {
      :raise    => true,    # Raise errors
      :marshal  => true,    # Marshal output
    }.merge(options)

    cmd = ['p4']
    cmd.push '-R' if opts[:marshal]
    cmd.push args
    cmd_str = cmd.respond_to?(:join) ? cmd.join(' ') : cmd

    Puppet.debug "environment: #{config}"
    Puppet.debug "command: #{cmd_str}"

    hash = Hash.new
    Open3.popen3(config, cmd_str) do |i, o, e, t|
      # Send input stream if provided
      if(opts[:input])
        Puppet.debug "input:\n" + opts[:input]
        i.write opts[:input]
        i.close
      end

      if(opts[:marshal])
        hash = Marshal.load(o)
      else
        hash['data'] = o.read
      end

      # Raise errors, Perforce or Exec
      if(opts[:raise] && !e.eof && t.value != 0)
        raise Puppet::Error, "\nP4: #{e.read}"
      end
      if(opts[:raise] && hash['code'] == 'error' && t.value != 0)
        raise Puppet::Error, "\nP4: #{hash['data']}"
      end
    end

    Puppet.debug "hash: #{hash}\n"
    return hash
  end

  # helper method as cstat does not Marshal
  def marshal_cstat(hash)
    data = hash['data']
    code = 'error'

    list = Array.new
    change = Hash.new
    data.each_line do |l|
      p = /^\.\.\. (.*) (.*)$/
      m = p.match(l)
      if m
        change[m[1]] = m[2]
        if m[1] == 'status'
          code = 'stat'
          list.push change
          change = Hash.new
        end
      end
    end

    hash = Hash.new
    hash.store 'code', code
    hash.store 'data', list
    return hash
  end

end
