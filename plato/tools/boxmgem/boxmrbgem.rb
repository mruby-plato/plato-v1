#!/usr/bin/env ruby
#
# boxmrbgems.rb - box selected mrbgems to 'user.gembox' and 'mrbgems.lst' 
#
# Usage: ruby boxmrbgems.rb <work-path> [<suffix0>, [<suffix1>, [...]]]
#   work-path:  Working directory path.
#   suffix0..N:  mgem list file suffix. (enzi, raspi, ...)
#
require 'json'

WORKPATH = ARGV[0] ? ARGV[0] : '.'
MGEM_SUFFIXS = ARGV[1..-1]

SELECTEDLIST  = File.join(WORKPATH, 'selected-mrbgems.lst')
GEMBOX_HOST   = File.join(WORKPATH, 'user-host.gembox')
GEMBOX_TARGET = File.join(WORKPATH, 'user-target.gembox')
OUTMGEMLIST   = File.join(WORKPATH, 'mrbgems.lst')

K_MGEM  = 'mrbgems'
K_NAME  = 'name'
K_PROT  = 'protocol'
K_REPO  = 'repository'
K_DEP   = 'dependencies'

MGEM_PREFIX = 'mruby-plato'

$srcpath = File.join(File.expand_path(File.dirname(__FILE__)), 'mgemlist')

# mrbgems list for simulator
DEF_SIM_MGEM = [
  {K_NAME=>'mruby-eval',              K_REPO=>'../mruby/mrbgems/mruby-eval'},
  {K_NAME=>'mruby-io',                K_REPO=>'https://github.com/iij/mruby-io.git'},
  {K_NAME=>'mruby-pack',              K_REPO=>'https://github.com/iij/mruby-pack.git'},
  {K_NAME=>'mruby-socket',            K_REPO=>'https://github.com/iij/mruby-socket.git'},
  {K_NAME=>'mruby-plato-sim-client',  K_REPO=>'../mrbgems/mruby-plato-sim-client'}
]

# mrbgems list files
MGEMLISTFILES = [
  'mgem-com.lst',
  'mgem-dev.lst',
  'mgem-ext.lst',
  'mgem-core.lst',
  'mgem-board.lst',
  'mgem-sim.lst'
]
# add board dependent mrbgems list
MGEM_SUFFIXS.each {|suff|
  MGEMLISTFILES << "mgem-#{suff}.lst"
}

# load supported mrbgems list
mgemlist = MGEMLISTFILES.inject([]) {|list, file|
  begin
    json = File.open(File::join($srcpath, file)) {|f| JSON::parse(f.read)}
  rescue
    raise "Cannot open mrbgems list (#{file})"
  end
  list += json[K_MGEM]
}

# load selected mrbgems list
selected = File.open(SELECTEDLIST) {|f| f.readlines}
usemgem = selected.inject([]) {|t, target|
  t += mgemlist.find_all {|gem|
    gem[K_NAME] == target.chomp
  }
}

# add dependencies
count = 0
while count != usemgem.size
  prvcnt = count
  count = usemgem.size
  usemgem[prvcnt..-1].each {|use|
    # dependencies
    if deps = use[K_DEP]
      deps.each {|dep|
        usemgem += mgemlist.find_all {|gem|
          gem[K_NAME] == dep[K_NAME]
        } unless usemgem.find_index {|x| x[K_NAME] == dep[K_NAME]}
      }
    end
  }
end
# usemgem.each {|gem| puts gem[K_NAME]}

# add board dependencies
usemgem_target = usemgem.clone
MGEM_SUFFIXS.each {|suff|
  count = 0
  while count != usemgem_target.size
    prvcnt = count
    count = usemgem_target.size
    usemgem_target[prvcnt..-1].each {|use|
      # brdmgem = use[K_NAME] + MGEM_SUFFIX
      brdmgem = use[K_NAME] + '-' + suff
      usemgem_target += mgemlist.find_all {|gem|
        gem[K_NAME] == brdmgem
      } unless usemgem_target.find_index {|x| x[K_NAME] == brdmgem}
    }
  end
}
# puts "<<mgem-board>>";usemgem_target.each {|gem| puts gem[K_NAME]}

# add libraries for simulator
usemgem_simulator = usemgem.clone
count = 0
while count != usemgem_simulator.size
  prvcnt = count
  count = usemgem_simulator.size
  usemgem_simulator[prvcnt..-1].each {|use|
    simmgem = use[K_NAME] + '-sim'
    usemgem_simulator += mgemlist.find_all {|gem|
      gem[K_NAME] == simmgem
    } unless usemgem_simulator.find_index {|x| x[K_NAME] == simmgem}
  }
end
usemgem_simulator += DEF_SIM_MGEM
# puts "<<mgem-simulator>>";usemgem_simulator.each {|gem| puts gem[K_NAME]}

# make user-target.gembox
[
  {:gembox => GEMBOX_HOST,   :gems => usemgem_simulator},
  {:gembox => GEMBOX_TARGET, :gems => usemgem_target},
].each {|gem|
  File.open(gem[:gembox], 'w') {|f|
    f.puts 'MRuby::GemBox.new do |conf|'
    gem[:gems].each {|mgem|
      if mgem[K_REPO]
        prot = mgem[K_REPO].include?('://') ? ':git => ' : ''
        f.puts "  conf.gem #{prot}#{mgem[K_REPO].inspect}"
      end
    }
    f.puts 'end'
  }
}

# make use mrbgems list (mrbgems.lst)
File.open(OUTMGEMLIST, 'w') {|f|
  usemgem_target.each {|mgem|
    if mgem[K_REPO] && !mgem[K_REPO].include?('://')
      if mgem[K_REPO].include?('mruby-plato')
        f.print('../')
      else
        f.print('build/')
      end
    end
    f.puts "mrbgems/#{mgem[K_NAME]}"
  }
}
