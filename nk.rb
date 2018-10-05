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
end
