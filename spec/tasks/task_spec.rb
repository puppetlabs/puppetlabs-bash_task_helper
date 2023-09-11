require 'spec_helper'
require 'json'

describe 'bash_task_helper' do
  context 'when using the helper script' do
    it {
      # Tasks expect certain PT_ environment variables to be set
      # We only need _installdir, so set it one directory up from the module root
      ENV['PT__installdir'] = File.join(File.dirname(__FILE__), '../fixtures/modules/')

      # Get the path to the task based on the absolute path of this file
      task = File.join(File.dirname(__FILE__), '../../examples/mytask.sh')
      out = `#{task}`
      # Success for this task is essentially determined by if we get a valid JSON object back
      expect(['error', 'success'].include?(out['status']))
    }
  end
end
