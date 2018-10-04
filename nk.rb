class NKnode
  attr_reader :id
  attr_reader :inputs
  attr_accessor :scores

  def initialize(id,inputs=[])
    @id = id
    @inputs = [id] + inputs
    @scores = Hash.new { |hash, key| hash[key] = random_score() }
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
