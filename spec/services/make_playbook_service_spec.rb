describe MakePlaybookService do
  let(:release) { Release.find_by_name('Web html flat release') }

  let(:release_order) do
    # second release order has two applications
    #   WEBv1 1.0.0
    #   TEST APPLICATION 2.0.0
    #   deployment on DEV PROD
    release.release_orders.second
  end

  let(:release_dir) { "/tmp/opt/putit/playbooks/web_html_flat_release_#{release.id}" }

  let(:web_v1_path) { File.join(release_dir, 'WEBv1-1.0.0') }

  let(:web_v1_path_dev) { File.join(release_dir, 'WEBv1-1.0.0', 'dev') }

  let(:web_v1_path_prod) { File.join(release_dir, 'WEBv1-1.0.0', 'prod') }

  let(:test_application_v2_path) { File.join(release_dir, 'TEST_APPLICATION-2.0.0') }

  before(:each) do
    MemFs.activate!

    service = MakePlaybookService.new release_order
    service.make_playbook!
  end

  after(:each) do
    MemFs.deactivate!
  end

  describe 'root release directory' do
    it 'should make directory for playbook - "name + id"' do
      expect(File.directory?(release_dir)).to be true
    end
  end

  describe 'application root directory' do
    it 'should make directory for applications' do
      expect(File.directory?(web_v1_path)).to be true
      expect(File.directory?(test_application_v2_path)).to be true
    end

    it 'should make inventory files' do
      expect(File.exist?(web_v1_path_dev)).to be true

      web_v1_inventory_dev_content = File.read(File.join(web_v1_path_dev, 'inventory_dev'))
      expect(web_v1_inventory_dev_content).to include '[dev-WEBv1]'
      expect(web_v1_inventory_dev_content).to include 'testowyhost-1.com'
      expect(web_v1_inventory_dev_content).to include 'testowyhost-2.com'

      expect(File.exist?(web_v1_path_prod)).to be true

      web_v1_inventory_prod_content = File.read(File.join(web_v1_path_prod, 'inventory_prod'))
      expect(web_v1_inventory_prod_content).to include '[prod-WEBv1]'
      expect(web_v1_inventory_prod_content).to include 'testowyhost-1.com'
      expect(web_v1_inventory_prod_content).to include 'testowyhost-2.com'
    end

    describe 'pipeline yml files' do
      describe 'dev' do
        it 'should make yml files per pipeline' do
          copy_files_yml = File.join(web_v1_path_dev, '0_dev_pipeline_copy_files.yml')
          expect(File.exist?(copy_files_yml)).to be true

          copy_files_content = YAML.load_file(copy_files_yml)
          expect(copy_files_content[0]['name']).to eq 'Deploy playbook from pipeline copy_files for application: WEBv1 on environment dev'
          expect(copy_files_content[0]['hosts']).to eq 'all'
          expect(copy_files_content[0]['roles']).to eq ['copy_files/copy_artifacts']
        end
      end
    end
  end

  describe 'application credentials' do
    it 'should make directory for keys' do
      web_v1_keys = File.join(web_v1_path_dev, 'keys')
      expect(File.directory?(web_v1_keys)).to eq true

      web_v1_keys = File.join(web_v1_path_prod, 'keys')
      expect(File.directory?(web_v1_keys)).to eq true
    end

    it 'should save env credential files' do
      web_v1_keys_dev = File.join(web_v1_path_dev, 'keys')
      web_v1_dev_key = File.join(web_v1_keys_dev, 'dev-WEBv1_credential1.key')
      credential_1 = Credential.find_by_name('credential1')
      credential_1_private_key = credential_1.sshkey.private_key

      expect(File.exist?(web_v1_dev_key)).to eq true
      expect(File.read(web_v1_dev_key)).to include credential_1_private_key

      web_v1_keys_prod = File.join(web_v1_path_prod, 'keys')
      web_v1_prod_key = File.join(web_v1_keys_prod, 'prod-WEBv1_credential2.key')
      credential_2 = Credential.find_by_name('credential2')
      credential_2_private_key = credential_2.sshkey.private_key

      expect(File.exist?(web_v1_prod_key)).to eq true
      expect(File.read(web_v1_prod_key)).to include credential_2_private_key
    end
  end

  describe 'host credentials' do
    it 'should save host credential files' do
      web_v1_keys_dev = File.join(web_v1_path_prod, 'keys')
      web_v1_host_1_key = File.join(web_v1_keys_dev, 'testowyhost-1.com-prod-WEBv1_credential3.key')
      credential_3 = Credential.find_by_name('credential3')
      credential_3_private_key = credential_3.sshkey.private_key

      expect(File.exist?(web_v1_host_1_key)).to eq true
      expect(File.read(web_v1_host_1_key)).to include credential_3_private_key
    end
  end

  describe 'group_vars/all directory' do
    it 'should make group_vars/all directory' do
      web_v1_group_vars = File.join(web_v1_path_dev, 'group_vars', 'all')
      expect(File.directory?(web_v1_group_vars)).to be true

      web_v1_group_vars = File.join(web_v1_path_prod, 'group_vars', 'all')
      expect(File.directory?(web_v1_group_vars)).to be true
    end

    it 'should make main.yml with all artifacts' do
      main_yml_path_dev = File.join(web_v1_path_dev, 'group_vars', 'all', 'artifacts.yml')
      expect(File.exist?(main_yml_path_dev)).to be true

      content = YAML.load_file(main_yml_path_dev)

      artifacts = content['artifacts']
      expect(artifacts).to be_truthy

      # properties are mocked in spec_helper.rb
      index = artifacts['index']

      expect(index).to be_truthy
      expect(index['version']).to eq '1.0.0'
      index_properties = index['properties']
      expect(index_properties['install_dir']).to eq '/tmp'
      expect(index_properties['source_path']).to eq '/opt/source/index/html/1.0.0/index.html'
      expect(index_properties['mode']).to eq '0666'

      other = artifacts['other']
      expect(other).to be_truthy
      expect(other['version']).to eq '1.4.1'
      other_properties = other['properties']
      expect(other_properties['install_dir']).to eq '/tmp'
      expect(other_properties['source_path']).to eq '/opt/source/other/html/1.4.1/other.html'
      expect(other_properties['mode']).to eq '0666'
    end
  end

  describe 'roles directory structure' do
    it 'should make roles directory' do
      expect(File.directory?(File.join(web_v1_path_dev, 'roles'))).to be true

      test_application_v2_roles = File.join(test_application_v2_path, 'test', 'roles')
      expect(File.directory?(test_application_v2_roles)).to be true
    end

    describe 'envs and pipelines' do
      describe 'dev' do
        let(:copy_files_pipeline) { File.join(web_v1_path_dev, 'roles', 'copy_files') }
        let(:send_notifications_pipeline) { File.join(web_v1_path_dev, 'roles', 'send_notifications') }

        it 'should make directories per pipelines' do
          expect(File.directory?(copy_files_pipeline)).to be true

          expect(File.directory?(send_notifications_pipeline)).to be true
        end

        describe 'steps' do
          let(:copy_artifacts) { File.join(copy_files_pipeline, 'copy_artifacts') }

          describe 'copy_artifacts' do
            it 'should make copy_artifacts directory' do
              expect(File.directory?(copy_artifacts)).to be true
            end

            describe 'steps/copy_artifacts/tasks' do
              it 'should make tasks/main.yml' do
                file_name = File.join(copy_artifacts, 'tasks', 'main.yml')
                expect(File.exist?(file_name)).to be true
                content = File.read(file_name)

                MemFs.deactivate!
                original_content = File.binread('./db/seed/step_copy_artifacts/tasks/main.yml')

                expect(content).to eq original_content
              end
            end

            describe 'steps/copy_artifacts/files' do
              it 'should make putit_test.file' do
                file_name = File.join(copy_artifacts, 'files', 'putit_test.file')
                expect(File.exist?(file_name)).to be true
                content = File.read(file_name)

                MemFs.deactivate!
                original_content = File.binread('./db/seed/step_copy_artifacts/files/putit_test.file')

                expect(content).to eq original_content
              end
            end

            describe 'steps/copy_artifacts/templates' do
              it 'should make putit_test.conf.j2' do
                file_name = File.join(copy_artifacts, 'templates', 'putit_test.conf.j2')
                expect(File.exist?(file_name)).to be true
                content = File.read(file_name)

                MemFs.deactivate!
                original_content = File.binread('./db/seed/step_copy_artifacts/templates/putit_test.conf.j2')

                expect(content).to eq original_content
              end
            end

            describe 'steps/copy_artifacts/vars' do
              it 'should make main.yml' do
                file_name = File.join(copy_artifacts, 'vars', 'main.yml')
                expect(File.exist?(file_name)).to be true
                content = File.read(file_name)

                MemFs.deactivate!
                original_content = File.binread('./db/seed/step_copy_artifacts/vars/main.yml')

                expect(content).to eq original_content
              end
            end
          end
        end
      end

      describe 'prod' do
        it 'should make directories per pipelines' do
          copy = File.join(web_v1_path_prod, 'roles', 'copy_files')
          expect(File.directory?(copy)).to be true

          notification = File.join(web_v1_path_prod, 'roles', 'send_notifications')
          expect(File.directory?(notification)).to be true
        end
      end
    end
  end
end
