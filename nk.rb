class NKnode
  attr_reader :id
  attr_reader :inputs
  attr_accessor :scores
  attr_accessor :state

  def initialize(id,inputs=[])
    @id = id
    set_inputs(inputs)
    @scores = Hash.new { |hash, key| hash[key] = random_score() }
  end

  def set_inputs(other_nodes)
    @inputs = [@id] + other_nodes
  end

  def score(state)
    state_size = state.length
    substate = @inputs.collect {|i| state[i % state_size]}
    @scores[substate]
  end

  def random_score
    return rand(1024)
  end
end


class NKnetwork
  attr_accessor :nodes

  def initialize(nodes,wiring=[])
    @nodes = nodes.times.collect {|i| NKnode.new(i)}
    set_wiring(wiring)
  end

  def input_graph
    @nodes.collect {|n| n.inputs}
  end

  def set_wiring(new_inputs)
    new_inputs.each_with_index do |new_nodes,idx|
      @nodes[idx].set_inputs(new_nodes)
    end
  end

  def evaluate_state(state)
    contributions = @nodes.collect {|n| n.score(state)}
    return contributions
  end

  def complete_network
    size = @nodes.length
    @nodes.collect.with_index do |n,idx|
      (0..size-1).to_a - [idx]
    end
  end
end

class NKsearcher
  attr_accessor :history
  attr_reader :network
  attr_accessor :state

  def initialize(network)
    @network = network
    @history = []
  end

  def random_state
    @network.nodes.length.
      times.collect {rand(2)}
  end

  def point_mutant(state,position=nil,possible=[0,1])
    where = position || rand(state.length)
    new_state = state.dup
    old_val = new_state[where]
    new_state[where] = (possible - [old_val]).sample
    return new_state
  end

  def neighbors(state,possible=[0,1])
    state.collect.with_index do |s,idx|
      point_mutant(state,idx,possible)
    end
  end

  def mutant_walk(start,changes,length)
    (1...length).inject([start]) do |walk,i|
      next_state = walk[-1].dup
      positions = (0...next_state.length).to_a.sample(changes)
      positions.each {|p| next_state}
      walk << neighbors(walk[-1]).sample
    end
  end

  def hamming(s1,s2)
    diffs = s1.select.each_with_index do |item,idx|
      s2[idx] != item
    end
    diffs.count
  end

  def lexicase_sort(states,index)
    netsize = states[0].length
    states.each {|s| @network.nodes[index].scores[s]}
    return states.shuffle.sort_by do |s|
      @network.nodes[index].scores[s]
    end
  end

  def totalistic_sort(states)
    states.shuffle.sort_by do |s|
      @network.evaluate_state(s).inject(:+)
    end
  end
end
