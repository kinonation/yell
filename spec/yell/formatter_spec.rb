require 'spec_helper'

describe Yell::Formatter do

  let(:logger) { Yell::Logger.new(:name => 'Yell') }
  let(:event) { Yell::Event.new(logger, 1, 'Hello World!') }
  let(:time) { Time.now }

  let(:pattern) { "%m" }
  let(:formatter) { Yell::Formatter.new(pattern) }

  before do
    Timecop.freeze(time)
  end

  describe "#format" do
    subject { formatter.format(event) }

    context "%m" do
      let(:pattern) { "%m" }
      it { should eq(event.messages.join(' ')) }
    end

    context "%l" do
      let(:pattern) { "%l" }
      it { should eq(Yell::Severities[event.level][0,1]) }
    end

    context "%L" do
      let(:pattern) { "%L" }
      it { should eq(Yell::Severities[event.level]) }
    end

    context "%d" do
      let(:pattern) { "%d" }
      it { should eq(event.time.iso8601) }
    end

    context "%p" do
      let(:pattern) { "%p" }
      it { should eq(event.pid.to_s) }
    end

    context "%P" do
      let(:pattern) { "%P" }
      it { should eq(event.progname) }
    end
    context "%t" do
      let(:pattern) { "%t" }
      it { should eq(event.thread_id.to_s) }
    end

    context "%h" do
      let(:pattern) { "%h" }
      it { should eq(event.hostname) }
    end

    context ":caller" do
      let(:_caller) { [nil, nil, "/path/to/file.rb:123:in `test_method'"] }

      before do
        any_instance_of(Yell::Event) do |e|
          stub(e).file { "/path/to/file.rb" }
          stub(e).line { "123" }
          stub(e).method { "test_method" }
        end
      end

      context "%F" do
        let(:pattern) { "%F" }
        it { should eq("/path/to/file.rb") }
      end

      context "%f" do
        let(:pattern) { "%f" }
        it { should eq("file.rb") }
      end

      context "%M" do
        let(:pattern) { "%M" }
        it { should eq("test_method") }
      end

      context "%n" do
        let(:pattern) { "%n" }
        it { should eq("123") }
      end
    end

    context "%N" do
      let(:pattern) { "%N" }
      it { should eq("Yell") }
    end
  end

  describe "#format from presets" do
    subject { formatter.format(event) }

    context "NoFormat" do
      let(:pattern) { Yell::NoFormat }
      it { should eq("Hello World!") }
    end

    context "DefaultFormat" do
      let(:pattern) { Yell::DefaultFormat }
      it { should eq("#{time.iso8601} [ INFO] #{$$} : Hello World!")  }
    end

    context "BasicFormat" do
      let(:pattern) { Yell::BasicFormat }
      it { should eq("I, #{time.iso8601} : Hello World!") }
    end

    context "ExtendedFormat" do
      let(:pattern) { Yell::ExtendedFormat }
      it { should eq("#{time.iso8601} [ INFO] #{$$} #{Socket.gethostname} : Hello World!") }
    end
  end

  describe "#format from exception" do
    let(:exception) { StandardError.new( "This is an Exception" ) }
    let(:event) { Yell::Event.new(logger, 1, exception) }
    subject { formatter.format(event) }

    before do
      mock(exception).backtrace.times(any_times) { ["backtrace"] }
    end

    it { should eq("StandardError: This is an Exception\n\tbacktrace") }
  end

  describe "#format from hash messages" do
    let(:hash) { { :test => 'message' } }
    let(:event) { Yell::Event.new(logger, 1, hash) }
    subject { formatter.format(event) }

    it { should eq("test=message") }
  end

end

