class SentenceSplitter
  # Functionally, this class is a port of perl's Lingua::EN::Sentence module.

  EOS         = "\001"                  ## END OF SENTENCE
  P           = /[\.!?]/                ## PUNCTUATION
  AP          = /(?:'|"|»|\)|\]|\})?/   ## AFTER PUNCTUATION
  PAP         = /#{P}#{AP}/

  PEOPLE      = [ 'jr', 'mr', 'mrs', 'ms', 'dr', 'prof', 'sr', "sens?", "reps?", 'gov', "attys?", 'supt',  'det', 'rev' ]
  ARMY        = [ 'col','gen', 'lt', 'cmdr', 'adm', 'capt', 'sgt', 'cpl', 'maj' ]
  INSTITUTES  = [ 'dept', 'univ', 'assn', 'bros' ]
  COMPANIES   = [ 'inc', 'ltd', 'co', 'corp' ]
  PLACES      = [ 'arc', 'al', 'ave', "blv?d", 'cl', 'ct', 'cres', 'dr', "expy?",
                  'dist', 'mt', 'ft',
                  "fw?y", "hwa?y", 'la', "pde?", 'pl', 'plz', 'rd', 'st', 'tce',
                  'Ala' , 'Ariz', 'Ark', 'Cal', 'Calif', 'Col', 'Colo', 'Conn',
                  'Del', 'Fed' , 'Fla', 'Ga', 'Ida', 'Id', 'Ill', 'Ind', 'Ia',
                  'Kan', 'Kans', 'Ken', 'Ky' , 'La', 'Me', 'Md', 'Is', 'Mass',
                  'Mich', 'Minn', 'Miss', 'Mo', 'Mont', 'Neb', 'Nebr' , 'Nev',
                  'Mex', 'Okla', 'Ok', 'Ore', 'Penna', 'Penn', 'Pa'  , 'Dak',
                  'Tenn', 'Tex', 'Ut', 'Vt', 'Va', 'Wash', 'Wis', 'Wisc', 'Wy',
                  'Wyo', 'USAFA', 'Alta' , 'Man', 'Ont', 'Qué', 'Sask', 'Yuk']
  MONTHS      = ['jan','feb','mar','apr','may','jun','jul','aug','sep','oct','nov','dec','sept']
  MISC        = [ 'vs', 'etc', 'no', 'esp' ]

  @abbreviations  = [ PEOPLE, ARMY, INSTITUTES, COMPANIES, PLACES, MONTHS, MISC ].flatten

  class << self
    attr_accessor :abbreviations
  end

  attr_reader :text

  def self.get_sentences(text)
    return self.new(text).sentences
  end

  def initialize(text)
    self.text = text
  end

  def text=(value)
    unless value == @text
      @text = value
      @sentences = nil
    end

    return @text
  end

  def sentences
    return unless self.text
    return @sentences if @sentences

    marked_text = self.text

    ### Start by roughly marking possible ends of sentences.

    marked_text.gsub!(/\n\s*\n/s,' ' + EOS)      ## double new-line means a different sentence.
    marked_text.gsub!(/(#{PAP}\s)/s,"\\1#{EOS}")
    marked_text.gsub!(/(\s\w#{P})/s,"\\1#{EOS}") # break also when single letter comes before punc.


    ### Next, remove markings from false positives.

    # Don't split after abbreviations with inline stops, like U.S.A.
    marked_text.gsub!(/([^-\w]\w#{PAP}\s)#{EOS}/s, '\1')
    marked_text.gsub!(/([^-\w]\w#{P})#{EOS}/s, '\1')

    # Don't split after single-letter abbreviations.
    marked_text.gsub!(/(\s\w\.\s+)#{EOS}/s, '\1')

    # Don't split after fake elipses (... used in place of …)
    marked_text.gsub!(/(\.\.\. )#{EOS}([[:lower:]])/s, '\1\2')

    # Don't split after quotes sentence-terminating punctuation (e.g. "." "?" "!" )
    marked_text.gsub!(/(['"]#{P}['"]\s+)#{EOS}/s, '\1')

    # Don't split after known abbreviations.
    SentenceSplitter.abbreviations.each do |abbrev|
      marked_text.gsub!(/((\s || ^)#{abbrev}#{PAP}\s)#{EOS}/is, '\1')
    end

    # Don't split after quote unless it is followed by a capital letter.
    marked_text.gsub!(/(["']\s*)#{EOS}(\s*[[:lower:]])/s, '\1\2')

    # Don't split: text . . some more text.
    marked_text.gsub!(/(\s\.\s)#{EOS}(\s*)/s, '\1\2')

    # Don't split when terminating puncuation is surrounded by spaces.
    marked_text.gsub!(/(\s#{PAP}\s)#{EOS}/s, '\1')


    ### Finally, re-mark items mistakenly stripped by the false-positive step .

    marked_text.gsub!(/(\D\d+)(#{P})(\s+)/s,"\\1\\2#{EOS}\\3")
    marked_text.gsub!(/(#{PAP}\s)(\s*\()/s, "\\1#{EOS}\\2")
    marked_text.gsub!(/('\w#{P})(\s)/s, "\\1#{EOS}\\2")

    marked_text.gsub!(/(\sno\.)(\s+)(?!\d)/is, "\\1#{EOS}\\2")

    # add EOS when you see "a.m." or "p.m." followed by a capital letter.
    marked_text.gsub!(/([ap]\.m\.\s+)([[:upper:]])/s, "\\1#{EOS}\\2")

    return @sentences = marked_text.split(EOS).compact.map{|s| s.strip }.reject{|s| s.empty? }
  end
end
