require 'spec_helper'

module CMIS
  PRIMARY_BASE_TYPES = [
    'cmis:document',
    'cmis:folder',
    'cmis:relationship',
     # 'cmis:policy',
    'cmis:item'
  ]

  describe Repository do
    it 'is supported by the library' do
      expect(repository.cmis_version_supported).to eq('1.1')
    end

    it 'has the correct id' do
      expect(repository.id).to eq(repository_id)
    end

    it 'has non nil fields' do
      expect(repository.id)              .to_not be_nil
      expect(repository.name)            .to_not be_nil
      expect(repository.product_version) .to_not be_nil
      expect(repository.description)     .to_not be_nil
      expect(repository.root_folder_id)  .to_not be_nil
      expect(repository.capabilities)    .to_not be_nil
      expect(repository.url)             .to_not be_nil
      expect(repository.changes_on_type) .to_not be_nil
      expect(repository.root_folder_url) .to_not be_nil
      expect(repository.product_name)    .to_not be_nil
      expect(repository.product_version) .to_not be_nil
    end

    it 'has a root folder' do
      root = repository.root
      expect(root).to be_a(CMIS::Folder)

      expect(root.cmis_object_id).to eq(repository.root_folder_id)
    end

    describe '#object' do
      it 'returns the object' do
        id = repository.root_folder_id
        object = repository.object(id)
        expect(object).to be_a(CMIS::Folder)
        expect(object.cmis_object_id).to eq(id)
      end
    end

    describe '#find_object' do
      it 'returns the object when it is present' do
        object = repository.find_object('cmis:folder', 'cmis:name' => 'root')
        expect(object).to be_a(CMIS::Folder)
      end
      it 'returns nil when it is not present' do
        object = repository.find_object('cmis:folder', 'cmis:name' => 'rat')
        expect(object).to be_nil
      end
      it 'returns nil when it is not present (bis)' do
        object = repository.find_object('cmis:folder', 'cmis:name' => nil)
        expect(object).to be_nil
      end
    end

    describe '#count_objects' do
      it 'returns 1 folder (which is the root folder)' do
        count = repository.count_objects('cmis:folder')
        expect(count).to eq 1
      end
      it 'returns 0 documents' do
        count = repository.count_objects('cmis:document')
        expect(count).to eq 0
      end
    end

    describe '#new_[document|folder|relationship|item|policy|type]' do
      it 'returns the correct type' do
        expect(repository.new_document)     .to be_a Document
        expect(repository.new_folder)       .to be_a Folder
        expect(repository.new_relationship) .to be_a Relationship
        expect(repository.new_item)         .to be_a Item
        expect(repository.new_policy)       .to be_a Policy
        expect(repository.new_type)         .to be_a Type
      end
    end

    context 'type related method' do
      before :all do
        create_apple_type
      end

      after :all do
        repository.type('apple').delete
      end

      describe '#type' do
        it 'returns the type for primitive types' do
          PRIMARY_BASE_TYPES.each do |t|
            type = repository.type(t)
            expect(type).to be_a(CMIS::Type)
            expect(type.id).to eq(t)
          end
        end
      end

      describe '#type?' do
        it 'returns true for a present type' do
          expect(repository.type?('apple')).to be true
        end

        it 'returns false for an absent type' do
          expect(repository.type?('banana')).to be false
        end
      end

      describe '#types' do
        it 'includes a present type' do
          type_array = repository.types.map(&:id)
          expect(type_array).to include('apple')
        end

        it 'does not include an absent type' do
          type_array = repository.types.map(&:id)
          expect(type_array).to_not include('banana')
        end
      end

      describe '#type' do
        it 'returns the type' do
          apple = repository.type('apple')
          expect(apple).to be_a CMIS::Type
          expect(apple.id).to eq('apple')
        end
      end

      describe '#type_tree' do
        it 'returns type tree' do
          type_tree = repository.type_tree
          expect(type_tree).to be_a(Array)
          expect(type_tree.size).to eq 5
          ids = type_tree.map { |elem| elem['type']['id'] }
          expect(ids).to include('cmis:document', 'cmis:folder', 'cmis:item', 'cmis:relationship', 'cmis:secondary')
          document_type = type_tree.select { |elem| elem['type']['id'] == 'cmis:document' }.first
          document_subtypes = document_type['children']
          expect(document_subtypes.size).to eq 1
          expect(document_subtypes.first['type']['id']).to eq 'apple'
        end
      end

      def create_apple_type
        type = repository.new_type
        type.id = 'apple'
        type.local_name = 'apple'
        type.query_name = 'apple'
        type.display_name = 'apple'
        type.parent_id = 'cmis:document'
        type.base_id = 'cmis:document'
        type.description = 'appel'
        type.creatable = true
        type.fileable = true
        type.queryable = true
        type.controllable_policy = true
        type.controllable_acl = true
        type.fulltext_indexed = true
        type.included_in_supertype_query = true
        type.content_stream_allowed = 'allowed'
        type.versionable = false
        type.add_property_definition(id: 'color',
                                     localName: 'color',
                                     queryName: 'color',
                                     displayName: 'color',
                                     description: 'color',
                                     propertyType: 'string',
                                     cardinality: 'single',
                                     updatability: 'readwrite',
                                     inherited: false,
                                     required: false,
                                     queryable: true,
                                     orderable: true)
        type.create
      end
    end
  end
end
