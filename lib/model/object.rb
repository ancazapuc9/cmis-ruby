require_relative 'server'
require_relative 'services'
require_relative 'folder'
require_relative 'document'
require_relative 'relationship'
require_relative 'policy'
require_relative 'item'

module Model
  class Object
    def self.create(raw)
      properties = raw[:properties]
      base_type_id = properties[:'cmis:baseTypeId'][:value]
      if 'cmis:folder'.eql?(base_type_id)
        Folder.create(raw)
      elsif 'cmis:document'.eql?(base_type_id)
        Document.create(raw)
      elsif 'cmis:relationship'.eql?(base_type_id)
        Relationship.create(raw)
      elsif 'cmis:policy'.eql?(base_type_id)
        Policy.create(raw)
      elsif 'cmis:item'.eql?(base_type_id)
        Item.create(raw)
      else
        raise "unexpected baseTypeId - #{base_type_id}"
      end
    end

    def initialize(raw)
      properties = raw[:properties]
      @repository_id = get_property_value(properties, :'cmis:repositoryId')
      @object_id = get_property_value(properties, :'cmis:objectId')
      @base_type_id = get_property_value(properties, :'cmis:baseTypeId')
      @object_type_id = get_property_value(properties, :'cmis:objectTypeId')
      @secondary_object_type_ids = get_property_value(properties, :'cmis:secondaryObjectTypeId')
      @name = get_property_value(properties, :'cmis:name')
      @description = get_property_value(properties, :'cmis:description')
      @created_by = get_property_value(properties, :'cmis:createdBy')
      @creation_date = get_property_value(properties, :'cmis:creationDate')
      @last_modified_by = get_property_value(properties, :'cmis:lastModifiedBy')
      @last_modification_date = get_property_value(properties, :'cmis:lastModificationDate')
      @change_token = get_property_value(properties, :'cmis:changeToken')
    end

    attr_reader :repository_id
    attr_reader :object_id
    attr_reader :base_type_id
    attr_reader :object_type_id
    attr_reader :secondary_object_type_ids
    attr_reader :name
    attr_reader :description
    attr_reader :created_by
    attr_reader :creation_date
    attr_reader :last_modified_by
    attr_reader :last_modification_date
    attr_reader :change_token

    attr_reader :properties

    def repository
      Server.repository(repository_id)
    end

    def object_type
      repository.type(object_type_id)
    end

    def delete
      Services.object.delete_object(repository_id, object_id, true)
    end

    def allowable_actions
      Services.object.get_allowable_actions(repository_id, object_id)
    end

    def relationships(direction)
      Services.relationship.get_object_relationships(repository_id, object_id, nil, direction, nil, nil, false, nil, nil).map do |r|
        Relationship.create(r)
      end
    end

    def policies
      Services.policy.get_applied_policies(repository_id, object_id, nil).map do |policy|
        Policy.create(policy)
      end
    end

    # remove from all folders
    def unfile
      Services.multi_filing.remove_object_from_folder(repository_id, object_id, nil)
    end


    def acls
      Services.acl.get_acl(repository_id, object_id, nil)
    end

    def add_aces(aces)
      Services.acl.apply_acl(repository_id, object_id, aces, nil, nil)
    end

    def remove_aces(aces)
      Services.acl.apply_acl(repository_id, object_id, nil, aces, nil)
    end

    private

    def get_property_value(properties, key)
      properties[key][:value]
    end
  end
end