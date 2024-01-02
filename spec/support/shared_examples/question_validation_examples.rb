RSpec.shared_examples "text must be question(s)" do |model|
  let(:m) { build(model) }

  it "is invalid with a nil text" do
    m.assign_attributes(text: nil)
    expect(m).not_to be_valid
    expect(
      m.errors.full_messages.map(&:downcase)
    ).to include "text can't be blank"
  end

  it "does not allow for text longer than 200 characters" do
    m.assign_attributes(text: "#{'n' * 200}?")
    expect(m).not_to be_valid
    expect(
      m.errors.full_messages
    ).to include "Text is too long (maximum is 200 characters)"
  end

  it "requires the text to be a question" do
    m.assign_attributes(text: "I don't think this should be allowed")
    expect(m).not_to be_valid
    expect(
      m.errors.full_messages
    ).to include "Text must only have questions"
  end

  it "allows multiple questions" do
    m.assign_attributes(text: "Are there wild things out there? Should we be careful?")
    expect(m).to be_valid
  end

  it "does not allow for sentences or exclamations" do
    [
      "Wow, things are great!",
      "Wow, things are great¡",
      "There are wild things out there."
    ].each do |sentence|
      m.assign_attributes(text: "#{sentence} So are you in?")
      expect(m).not_to be_valid
      expect(
        m.errors.full_messages
      ).to include "Text must only have questions"
    end
  end
end
