shared_examples 'A semipublic Subject' do
  describe '#default?' do
    describe 'with a default' do
      subject { @subject_with_default.default? }

      it { is_expected.to be(true) }
    end

    describe 'without a default' do
      subject { @subject_without_default.default? }

      it { is_expected.to be(false) }
    end
  end

  describe '#default_for' do
    describe 'without a default' do
      subject { @subject_without_default.default_for(@resource) }

      it 'Matches the default value' do
        expect(DataMapper::Ext.blank?(subject)).to eq true
      end

      it 'Is used as a default for the subject accessor' do
        is_expected.to eq @resource.__send__(@subject_without_default.name)
      end

      it 'Persists the value' do
        expect(@resource.save).to be(true)
        @resource = @resource.model.get!(*@resource.key)
        expect(@resource.without_default).to eq subject
      end
    end

    describe 'with a default value' do
      subject { @subject_with_default.default_for(@resource) }

      it 'Matches the default value' do
        if @default_value.is_a?(DataMapper::Resource)
          expect(subject.key).to eq @default_value.key
        else
          is_expected.to eq @default_value
        end
      end

      it 'Is used as a default for the subject accessor' do
        is_expected.to eq @resource.__send__(@subject_with_default.name)
      end

      it 'Persists the value' do
        expect(@resource.save).to be(true)
        @resource = @resource.model.get!(*@resource.key)
        expect(@resource.with_default).to eq subject
      end
    end

    describe 'with a default value responding to #call' do
      subject { @subject_with_default_callable.default_for(@resource) }

      it 'Matches the default value' do
        if @default_value.is_a?(DataMapper::Resource)
          expect(subject.key).to eq @default_value_callable.key
        else
          is_expected.to eq @default_value_callable
        end
      end

      it 'Is used as a default for the subject accessor' do
        is_expected.to eq @resource.__send__(@subject_with_default_callable.name)
      end

      it 'Persists the value' do
        expect(@resource.save).to be(true)
        @resource = @resource.model.get!(*@resource.key)
        expect(@resource.with_default_callable).to eq subject
      end
    end
  end
end
