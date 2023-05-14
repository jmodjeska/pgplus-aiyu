# frozen_string_literal: true

require_relative '../lib/strings'
require_relative '../lib/constants'

describe Strings do
  include Strings

  it 'cleans ANSI strings' do
    ansi_string = "\u{0000}\e[32m¿Cuántas cabras \r\nle gustaría comprar?\e[m\n"
    result = clean_ansi(ansi_string)
    expect(result).to eq('Cuntas cabras le gustara comprar?')
  end

  it 'turns a brief string into an array of one element' do
    short_string = 'Greetings, earthling.'
    result = process_message(short_string)
    expect(result).to eq(['Greetings, earthling.'])
  end

  it 'processes a long string into 250-char chunks with trailing spaces' do
    long_string = "I ain't tryin' to say I'm gonna rule the world or nothing "\
    "like that, but I'm doin' all right. Got me a nice little business goin' "\
    "on, and I know how to take care of myself out here. But I ain't "\
    "forgivin' nobody for nothin'. Ain't no need for me to be walkin' "\
    'around here being mad all the time. That just take too much energy, '\
    "and I ain't got time for it. But when I got a good reason to be mad, "\
    "you better believe I'm gonna be mad."
    result = process_message(long_string)
    expect(result).to eq(
      [
        "I ain't tryin' to say I'm gonna rule the world or nothing like "\
        "that, but I'm doin' all right. Got me a nice little business goin' "\
        "on, and I know how to take care of myself out here. But I ain't "\
        "forgivin' nobody for nothin'. ",
        "Ain't no need for me to be walkin' around here being mad all the "\
        "time. That just take too much energy, and I ain't got time for it. "\
        'But when I got a good reason to be mad, you better believe '\
        "I'm gonna be mad. "
      ]
    )
  end

  it 'processes a long string with a numbered list' do
    numbered_string = '1. Frogs are amphibians, which means they can live '\
    "both on land and in water. 2. They don't drink water the way we do, "\
    'instead they absorb it through their skin. 3. Frogs lay their eggs in '\
    'water, and these eggs hatch into tadpoles which resemble fish. The '\
    'tadpoles then metamorphose into adult frogs.'
    result = process_message(numbered_string)
    expect(result).to eq(
      [
        '1. Frogs are amphibians, which means they can live both on land '\
        "and in water. 2. They don't drink water the way we do, "\
        'instead they absorb it through their skin. ',
        '3. Frogs lay their eggs in water, and these eggs hatch into '\
        'tadpoles which resemble fish. The tadpoles then metamorphose into '\
        'adult frogs. '
      ]
    )
  end

  it 'replaces a [[[TRUNCATED]]] flag with a message' do
    truncated_string = 'and the obnoxious, frozen stupidity of grown-ups '\
    'who still get off on making jokes about the unchosen features of other '\
    "human beings. Jokes about one's height, hair loss, one's name. You'll "\
    "find if you're short, bald, if you're a boy named Leslie [[[TRUNCATED]]]"
    result = process_message(truncated_string)
    expect(result).to eq(
      [
        'and the obnoxious, frozen stupidity of grown-ups who still get off '\
        'on making jokes about the unchosen features of other human beings. '\
        "Jokes about one's height, hair loss, one's name. ",
        'Sorry, there was more, but I truncated it due to length.'
      ]
    )
  end
end
