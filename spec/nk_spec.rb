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
      states = 10.times.collect {10.times.collect {rand(10)}}
      a = NKnode.new(0,[2,7])
      states.each {|s| a.score(s)}
      expect(a.scores.keys.length).to eq 10
      expected_substates = states.collect {|s| [0,2,7].collect {|i| s[i]}}
      expect(expected_substates).to eq a.scores.keys
    end
  end
end
