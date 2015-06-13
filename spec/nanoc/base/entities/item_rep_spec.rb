describe Nanoc::Int::ItemRep do
  describe '#compiled_content' do
    let(:item_rep) { Nanoc::Int::ItemRep.new(item, :name) }

    let(:item) { Nanoc::Int::Item.new(content, {}, '/foo') }

    let(:content) { Nanoc::Int::TextualContent.new('Hallo') }

    subject { item_rep.compiled_content(params) }

    let(:params) { {} }

    context 'binary' do
      let(:content) { Nanoc::Int::BinaryContent.new('/stuff.dat') }

      it 'raises' do
        expect { subject }
          .to raise_error(Nanoc::Int::Errors::CannotGetCompiledContentOfBinaryItem)
      end
    end
  end
end
