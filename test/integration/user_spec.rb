require_relative 'spec_helper'

describe 'User' do
  before do
    @aem = init_client

    # ensure user doesn't exist prior to testing
    @user = @aem.user('/home/users/s/', 'someuser')
    @user.delete unless @user.exists.data == false
    result = @user.exists
    expect(result.data).to eq(false)

    # create user
    result = @user.create('somepassword')
    expect(result.message).to match(%r{^User someuser created at /home/users/s/.+})
  end

  after do
  end

  describe 'test user create' do
    it 'should succeed existence check' do
      result = @user.exists
      expect(result.message).to match(%r{^User someuser exists at /home/users/s/.+})
      expect(result.data).to eq(true)
    end

    it 'should succeed permission setting' do
      result = @user.set_permission('/etc/replication', 'read:true,modify:true')
      expect(result.message).to eq('Permission read:true,modify:true on path /etc/replication set for user someuser')
    end

    # test the API, but don't change the admin password itself because the same
    # one is still needed for running the other tests
    it 'should succeed admin password change' do
      admin_password = ENV['aem_password'] || 'admin'
      result = @user.change_password(admin_password, admin_password)
      expect(result.message).to eq('User admin\'s password has been changed')
    end

    it 'should succeed created user password change' do
      aem = RubyAem::Aem.new(
        username: 'someuser',
        password: 'somepassword',
        protocol: ENV['aem_protocol'] || 'http',
        host: ENV['aem_host'] || 'localhost',
        port: ENV['aem_port'] ? ENV['aem_port'].to_i : 4502,
        debug: ENV['aem_debug'] ? ENV['aem_debug'] == 'true' : false
      )
      user = aem.user('/home/users/s/', 'someuser')
      result = user.change_password('somepassword', 'somenewpassword')
      expect(result.message).to eq('User someuser\'s password has been changed')
    end

    it 'should succeed being added to a group' do
      # ensure group doesn't exist prior to testing
      group = @aem.group('/home/groups/s/', 'somegroup')
      group.delete

      # create group
      result = group.create
      expect(result.message).to match(%r{^Group somegroup created at /home/groups/s/.+})

      # add user to group
      result = @user.add_to_group('/home/groups/s/', 'somegroup')
      expect(result.message).to eq('User/group someuser added to group somegroup')
    end

    it 'should raise error when setting permission for an inexisting user' do
      user = @aem.user('/home/users/s/', 'someinexistinguser')
      begin
        user.set_permission('/etc/replication', 'read:true,modify:true')
        raise
      rescue RubyAem::Error => e
        expect(e.message).to match(/^Unexpected response/)
      end
    end
  end
end
