require 'rubygems'
require 'hpricot'

Lamda = 'λ'
Square = '□'

class State
  attr_accessor :name, :is_initial, :is_final, :id

  def label
    return @name
  end
end

class Transition
  attr_accessor :read, :to, :from

  def label
    return @read
  end
end

class PDATransition < Transition
  attr_accessor :push, :pop

  def label
    return "#{@read}, #{@pop}; #{@push}"
  end
end

class TuringTransition < Transition
  attr_accessor :write, :move

  def label
    temp = []
    @read.length.times do |i|
      temp << "#{@read[i]}; #{@write[i]}, #{@move[i]}"
    end
    return temp.join(' | ')
  end
end

class JFF
  Supported = [:fa, :pda, :turing]
  def initialize( io )
    @doc = Hpricot.XML(io)
    typenode = @doc.at('/structure/type')
    raise 'Not a JFLap file' if typenode == nil or typenode.inner_text == nil
    @type = typenode.inner_text.to_sym
    raise 'Not an automaton understood by this program' unless Supported.index @type
    @states = nil
    @transitions = nil
  end

  def states
    if @states == nil
      jffstates = @doc / '/structure/automaton/state'
      @states = {}
      jffstates.each do |jffstate|
        state = State.new
        state.name = jffstate['name']
        state.is_initial = jffstate.at('initial') != nil
        state.is_final = jffstate.at('final') != nil
        state.id = jffstate['id']
        @states[state.id] = state
      end
    end
    return @states.values
  end

  def accepting_states
    states.select { |state| state.is_final }
  end

  def nonaccepting_states
    states.select { |state| not state.is_final }
  end

  def initial_states
    states.select { |state| state.is_initial }
  end

  def transitions
    if @transitions == nil
      @transitions = []
      states if @states == nil # populates @states
      (@doc / '/structure/automaton/transition').each do |jfftransition|
        transition = nil
        if @type == :pda
          transition = PDATransition.new
          transition.push = jfftransition.at('push').inner_text.strip
          transition.pop = jfftransition.at('pop').inner_text.strip
          transition.push = Lamda if transition.push == ''
          transition.pop = Lamda if transition.pop == ''
        elsif @type == :turing
          transition = TuringTransition.new
          ['read', 'write', 'move'].each do |sym|
            elements = jfftransition.search(sym)
            value = elements.collect do |e|
              text = e.inner_text.strip
              text = Square if text == ''
              text
            end
            transition.instance_variable_set('@' + sym, value)
          end
        else
          transition = Transition.new
        end
        transition.read = jfftransition.at('read').inner_text.strip unless transition.read
        transition.read = Lamda if transition.read == ''
        transition.from = @states[jfftransition.at('from').inner_text.strip]
        transition.to = @states[jfftransition.at('to').inner_text.strip]
        @transitions << transition
      end
    end
    return @transitions
  end
end

doc = File.open(ARGV[0], 'r') { |io| JFF.new(io) }

puts "digraph jff2dot {
  fontname=\"DejaVu Serif\";
  fontsize=10;
  node [fontname=\"DejaVu Serif\", fontsize=10];
  edge [fontname=\"DejaVu Serif\", fontsize=10];
  rankdir=LR;
  // accepting states
  node [shape=doublecircle] #{doc.accepting_states.map{ |state| state.id } * ' '};
  // nonaccepting states
  node [shape=circle] #{doc.nonaccepting_states.map{ |state| state.id } * ' '};
  // state labels"
doc.states.each do |state|
  puts "  #{state.id} [label=\"#{state.label}\"];"
end
puts "  // initial state markers"
doc.initial_states.each do |state|
  puts "  XXXjffinitial#{state.name} [shape=plaintext, label=\"\"];"
  puts "  XXXjffinitial#{state.name} -> #{state.id};"
end
puts "  // transitions"
doc.transitions.each { |transition| puts "  #{transition.from.id} -> #{transition.to.id} [label=\"#{transition.label}\"];"}
puts "}"
