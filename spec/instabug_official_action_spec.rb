describe Fastlane::Actions::InstabugOfficialAction do
  describe '#run' do
    it 'prints a message' do
      expect(Fastlane::UI).to receive(:message).with("The instabug_official plugin is working!")

      Fastlane::Actions::InstabugOfficialAction.run(nil)
    end
  end
end
