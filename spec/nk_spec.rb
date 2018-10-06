require "rspec"
require "./nk"

describe NKnode do
  describe 'ID' do
    it 'has an ID when initialized' do
      a = NKnode.new(29)
      expect(a.id).to eq 29
    end
  end

  describe 'inputs' do
    it 'has an inputs vector defaulting to just its own id' do
      a = NKnode.new(11)
      expect(a.inputs).to eq [11]
    end

    it 'inserts its id at the head of the inputs argument vector' do
      a = NKnode.new(11,[8,2,9])
      expect(a.inputs).to eq [11,8,2,9]
    end

    it "doesn't permit duplicates" do
      a = NKnode.new(11,[11,11,12,13,11])
      expect(a.inputs).to eq [11,12,13]
    end
  end

  describe 'scores' do
    it 'has an empty scores hash' do
      a = NKnode.new(2)
      a.scores = {}
    end

    it 'produces a score when passed a state vector' do
      a = NKnode.new(2,[3,4])
      expect(a.inputs).to eq [2,3,4]
      a.score([1,1,2,3,4,1,1,1,1,1])
      expect(a.scores.length).to be 1
      expect(a.scores.keys).to eq [[2,3,4]]
    end

    it 'looks up and returns score if it exists' do
      a = NKnode.new(2,[3,4])
      a.scores[[1,1,1]] = 999
      expect(a.score([0,0,1,1,1])).to eq 999
    end

    it 'uses modulo indices if the state passed in is too small' do
      a = NKnode.new(1,[33,44])
      expect(a.inputs).to eq [1,33,44]
      a.score([0,1,2,3,4,5])
      expect(a.scores.keys).to eq [[1,3,2]]
    end

    it 'uses modulo indices for negative input indices too' do
      a = NKnode.new(1,[0,-1])
      expect(a.inputs).to eq [1,0,-1]
      a.score([0,1,2,3,4,5])
      expect(a.scores.keys).to eq [[1,0,5]]
    end

    it 'can generate a random score' do
      a = NKnode.new(2)
      s = a.random_score
      expect(s.integer?).to be true
    end

    it "produces a new score if one doesn't exist yet" do
      a = NKnode.new(2)
      allow(a).to receive(:random_score) { 111 }
      expect(a.score([0,0,1])).to be 111
    end

    it 'records new scores in the hash' do
      a = NKnode.new(2,[0,1])
      s1 = a.score([0,0,1])
      s2 = a.score([0,0,1])
      expect(s2).to eq s1
      s3 = a.score([2,3,4])
      expect(s3).not_to eq s2
    end

    it 'is possible to pass several vectors of state to the same node and get scores' do
      states = 10.times.collect {10.times.collect {rand()}}
      a = NKnode.new(0,[2,7])
      states.each {|s| a.score(s)} # update their scores tables
      expect(a.scores.keys.length).to eq 10
      expected_substates = states.collect {|s| [0,2,7].collect {|i| s[i]}}
      expect(expected_substates).to eq a.scores.keys
    end
  end
end

describe 'NKnetwork' do
  it 'should have nodes' do
    tenner = NKnetwork.new(10)
    expect(tenner.nodes.length).to eq 10
    tenner.nodes.each {|n| expect(n).to be_a_kind_of(NKnode)}
  end

  it 'should be possible to set the wiring' do
    three = NKnetwork.new(3)
    three.set_wiring([[2,11], [], [9]])
    expect(three.input_graph).to eq [[0,2,11], [1], [2,9]]
  end

  it 'should be possible to set the initial wiring to a an arbitrary graph' do
    twelve_star = NKnetwork.new(12,[[9]]*12)
    expect(twelve_star.input_graph).to eq [[0, 9], [1, 9], [2, 9], [3, 9], [4, 9], [5, 9], [6, 9], [7, 9], [8, 9], [9], [10, 9], [11, 9]]
  end

  it 'has a helper for producing a complete network' do
    five = NKnetwork.new(5)
    expect(five.complete_network).to eq [[1,2,3,4],[0,2,3,4],[0,1,3,4],[0,1,2,4],[0,1,2,3]]
  end
end


describe 'exercising a network' do
  it 'should produce scores for states' do
    three = NKnetwork.new(3)
    three.set_wiring([[1],[2],[3]])
    expect(three.input_graph).to eq [[0, 1], [1, 2], [2, 3]]
    states = [0,1].repeated_permutation(3).to_a # all possible states
    expect(states.length).to eq 8
    scores = states.collect {|s| three.evaluate_state(s)}
    expect(scores.length).to eq 8
    expect(scores.collect(&:length)).to eq [3]*8
  end
end

describe 'NKsearcher' do
  it 'can produce a random sampled binary state' do
    n20 = NKnetwork.new(20)
    n20searcher = NKsearcher.new(n20)
    s1 = n20searcher.random_state
    expect(s1.length).to eq 20
    expect(s1.uniq.length).to eq 2
  end

  it 'can produce a mutant' do
    n10 = NKnetwork.new(10)
    n10searcher = NKsearcher.new(n10)
    s1 = [0]*10
    s1m = n10searcher.point_mutant(s1,7)
    expect(s1m[7]).not_to eq 0
    s1m = n10searcher.point_mutant(s1,7,[0,99])
    expect(s1m[7]).to eq 99
    s1m = n10searcher.point_mutant(s1)
    expect(n10searcher.hamming(s1,s1m)).to eq 1
  end

  it 'can produce all 1-mutant neighbors of a state' do
    n5 = NKnetwork.new(5)
    n5searcher = NKsearcher.new(n5)
    s1 = [0,0,0,0,0]
    sm = n5searcher.neighbors(s1)
    expect(sm).to include([1,0,0,0,0],
                          [0,1,0,0,0],
                          [0,0,1,0,0],
                          [0,0,0,1,0],
                          [0,0,0,0,1]
                          )
  end

  it 'can produce a random walk' do
    n5 = NKnetwork.new(5)
    n5searcher = NKsearcher.new(n5)
    s1 = [0,0,0,0,0]
    sm = n5searcher.mutant_walk(s1,1,10)
    expect(sm.length).to be 10
    (0..3).each do |idx|
      d = n5searcher.hamming(sm[idx],sm[idx+1])
      expect(d).to eq 1
    end
  end

  it 'can do a lexicase sort of a collection of states' do
    n20 = NKnetwork.new(20)
    n20.set_wiring(n20.complete_network)
    n20searcher = NKsearcher.new(n20)
    samples = 100.times.collect {n20searcher.random_state}
    l2 = n20searcher.lexicase_sort(samples,2)
    new_order = l2.collect do |s|
      n20searcher.network.nodes[2].scores[s]
    end
    expect(new_order).to eq new_order.sort
    l13 = n20searcher.lexicase_sort(samples,13)
    l13_order = l13.collect {|s|
      n20searcher.network.nodes[13].scores[s]}
    expect(new_order).not_to eq l13_order
    expect(l13_order.sort).to eq l13_order
  end

  it 'shuffles the states first to avoid bias from ties' do
    n6 = NKnetwork.new(6) #unconnected
    n6searcher = NKsearcher.new(n6)
    samples = 10.times.collect {n6searcher.random_state}
    samples.each {|s| n6.nodes[2].scores[s] = 999}
      # set every salient score to the same number
    l2a = n6searcher.lexicase_sort(samples,2)
    l2b = n6searcher.lexicase_sort(samples,2)
    expect(l2a).not_to eq l2b
  end

  it 'can do a totalistic sort of a collection of states' do
    n20 = NKnetwork.new(20)
    n20.set_wiring(n20.complete_network)
    n20searcher = NKsearcher.new(n20)
    samples = 100.times.collect {n20searcher.random_state}
    tots = n20searcher.totalistic_sort(samples)
    new_order = tots.collect do |s|
      n20searcher.network.evaluate_state(s).inject(:+)
    end
    expect(new_order).to eq new_order.sort
  end

  it 'shuffles the states to avoid bias from ties' do
    n6 = NKnetwork.new(6)
    n6searcher = NKsearcher.new(n6)
    samples = 10.times.collect {n6searcher.random_state}
    samples.each {|s| n6.evaluate_state(s)}
      # fill in "actual" values in @scores hashes
    n6.nodes.each {|n| n.scores.keys.each {|k| n.scores[k] = 999}}
      # set every score in every node to 999
    tots_a = n6searcher.totalistic_sort(samples)
    tots_b = n6searcher.totalistic_sort(samples)
    expect(tots_a).not_to eq tots_b
  end

end

# describe 'trying it out' do
#   it 'works for biggish systems' do
#     n = 200
#     nkn = NKnetwork.new(n)
#     net = (0..n-1).collect {|i| ((0..n-1).to_a - [i]).sample(1)}
#     nkn.set_wiring(net)
#     bigSearcher = NKsearcher.new(nkn)
#     s1 = [0]*n
#     guesses = 100.times.collect {bigSearcher.random_state}
#     scores =  guesses.collect {|s| bigSearcher.network.evaluate_state(s)}
#     # puts scores.collect {|s| s.inject(:+)}
#   end
# end
