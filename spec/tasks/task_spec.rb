require 'spec_helper'
require 'json'

describe 'bash_task_helper' do
  context 'when using the helper script' do
    subject(:task) do
      # Tasks expect certain PT_ environment variables to be set
      # We only need _installdir, so set it one directory up from the module root
      ENV['PT__installdir'] = File.join(File.dirname(__FILE__), '../fixtures/modules/')

      # Get the path to the task based on the absolute path of this file
      task = File.join(File.dirname(__FILE__), '../../examples/mytask.sh')
      out = `#{task}`
      JSON.parse(out)
    end

    before(:each) do
      ENV['PT_run_type'] = run_type.to_s
    end

    context 'when succeeding' do
      let(:run_type) { :pass }

      it { is_expected.to include('status' => 'success') }
      it { is_expected.to include('_output' => 'This task succeeded') }
    end

    context 'when failing' do
      let(:run_type) { :fail }

      it { is_expected.to include('status' => 'error') }
      it { is_expected.to include('_output' => 'This task failed') }
    end

    context 'when testing output functions' do
      let(:run_type) { :output }

      it { is_expected.to include('status' => 'success') }
      it { is_expected.to include('string1' => 'abcd') }
      it { is_expected.to include('string-numeric' => '42') }
      it { is_expected.to include('string2' => 'abcd') }
      it { is_expected.to include('number' => 42) }
      it { is_expected.to include('bool' => true) }
      it { is_expected.to include('complex-string' => "This is a \"complex string\".\n\tSecond line.") }
      it { is_expected.to include('escape-backslash' => '\ No newline') }
    end
  end
end
