require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "SentenceSplitter" do
  it "should split simple sentances" do
    sentences = ["See Spot.", "See Spot run.", "Run Spot, run!"]
    text = sentences.join(' ')

    SentenceSplitter.get_sentences(text).should == sentences
  end

  it "should split sentances at a double newline, regardless of other rules" do
    sentences = ["Hey Mr.","I'm going to Ore."]
    text = sentences.join("\n\n")

    SentenceSplitter.get_sentences(text).should == sentences
  end

  it "should not split following abbreviations with inline periods" do
    text = "The U.S.A. has many bridges."
    SentenceSplitter.get_sentences(text).should == [text]
  end

  it "should not split following single-letter abbreviations" do
    text = "I'm heading N. on the highway."
    SentenceSplitter.get_sentences(text).should == [text]
  end

  it "should split after three periods used as elipses before a capital letter" do
    sentences = %w(Five... Four... Three... Two... One...)
    text = sentences.join(' ')
    SentenceSplitter.get_sentences(text).should == sentences
  end

  it "should not split after three periods used as elipses (and followed by lowercase letters)" do
    text = "And then... the train arrived."
    SentenceSplitter.get_sentences(text).should == [text]
  end

  it "should not split when punctuation is referred to in quotes" do
    text = %q(Her eyes seemed to say "?", but the twitch of her hand screamed '!')
    SentenceSplitter.get_sentences(text).should == [text]
  end

  it "should not split following a quote, unless the quote is followed by a capital letter" do
    text = %q("Hello!" exclaimed Rachel)
    SentenceSplitter.get_sentences(text).should == [text]

    sentences = ['"Goodbye."', "She turned and walked away."]
    text = sentences.join(' ')
    SentenceSplitter.get_sentences(text).should == sentences
  end

  it "should not split after bare punctuation used in the middle of a sentance" do
    text = "I'm not . . really sure when ? this case would come up."
    SentenceSplitter.get_sentences(text).should == [text]
  end

  it "should split on A.M. or P.M. when they're followed by a capital letter" do
    sentances = ["It was beautiful in the a.m., but the storm came in the p.m.", "It was crazy!"]
    text = sentances.join(' ')
    SentenceSplitter.get_sentences(text).should == sentances
  end

  describe "avoiding known abbreviations" do
    SentenceSplitter.abbreviations.each do |abbrev|
      abbrev.gsub!('?','') #since we're not using abbrev in a regexp here
      it "should not split after '#{abbrev}'" do
        text = "#{abbrev}. Livingston, I presume."
        SentenceSplitter.get_sentences(text).should == [text]
      end
    end
  end
end