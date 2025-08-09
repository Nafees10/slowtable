module slowtable.combinator.base;

import std.traits,
			 std.bitmanip,
			 std.algorithm;

import utils.ds;

/// Combination Generator, Generic
public struct Combinator(Scorer, S...){
private:
	Heap!(Node!(Scorer, S), "a._score.score < b._score.score") frontier;
	const size_t[][] _groupChoices;

public:
	@disable this();
	this (S state, const BitArray[] clashMat, const size_t[][] groupChoices){
		Node!(Scorer, S) node = new Node!(Scorer, S)(state, clashMat, groupChoices);
		_groupChoices = groupChoices;
		frontier = new typeof(frontier);
		frontier.put(node);
		frontier.put(node);
		popFront();
	}

	@property void popFront(){
		frontier.popFront;
		while (!frontier.empty){
			Node!(Scorer, S) node = frontier.front;
			if (node._picks.keys.length == _groupChoices.length)
				return;
			frontier.popFront;
			foreach (Node!(Scorer, S) next; node.next)
				frontier.put(next);
		}
	}

	@property Node!(Scorer, S) front(){
		return frontier.front;
	}
	@property bool empty(){
		return frontier.heap.length == 0;
	}
}

/// A Combination
public struct Combination(Scorer){
	/// computed score
	public typeof(Scorer.score) score;
	/// set of picked options
	public Set!size_t picks;
}

/// A Node in the combinations tree
private final class Node(Scorer, S...){
private:
	/// to be passed to Scorer
	S _state;
	/// next descendent states
	Heap!(Node!(Scorer, S), "a._score.score < b._score.score") _next;
	/// selection options. `[groupIndex][OptionIndex]->OptionId`
	const size_t[][] _groupChoices;
	/// clashes bit array
	BitArray _clash;
	/// clash matrix
	const BitArray[] _clashMat;
	/// picked sids
	Set!size_t _picks;
	/// score
	public Scorer _score;

	this(Node!(Scorer, S) parent, const BitArray[] clashMat, size_t pick) {
		_state = parent._state;
		_clashMat = clashMat;
		_groupChoices = parent._groupChoices[1 .. $];
		_clash = parent._clash.dup;
		_clash &= _clashMat[pick];
		_picks.put(parent._picks.keys);
		_picks.put(pick);
		_score = Scorer(_state, parent._score, pick);
	}

	this(S state, const BitArray[] clashMat, const size_t[][] sids) pure {
		_state = state;
		_clashMat = clashMat;
		_groupChoices = sids;
		_clash = BitArray(
				new void[(_clashMat.length + (size_t.sizeof - 1)) / size_t.sizeof],
				_clashMat.length);
		_clash[] = true;
	}

	/// Returns: range of next nodes after this
	Heap!(Node!(Scorer, S), "a._score.score < b._score.score") next() {
		if (_next)
			return _next;
		_next = new typeof(_next); // new heap
		if (_groupChoices.length == 0 || _groupChoices[0].length == 0)
			return _next;
		foreach (size_t sid; _groupChoices[0].filter!(s => _clash[s] == true))
			_next.put(new Node!(Scorer, S)(this, _clashMat, sid));
		return _next;
	}

public:
	/// Returns: a usable view of this Node
	Combination!Scorer view() {
		return Combination!Scorer(cast(ptrdiff_t)this._score.score, this._picks);
	}
}
