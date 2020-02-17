Step.destroy_all
# create steps
step = Step.create!(name: 'copy_artifacts', template: true,
                    description: 'Copy artifacts based on properties',
                    properties_description: [{
                      name: 'source_path',
                      mandatory: true,
                      description: 'Source path of artifact. Should be an absolute path.'
                    }, {
                      name: 'install_dir',
                      mandatory: true,
                      description: 'Destination folder. Should be an absolute path.'
                    }, {
                      name: 'mode',
                      mandatory: true,
                      description: 'Filemode to set on.'
                    }])

step.files.physical_files << PhysicalFile.create!(name: 'putit_test.file', content: File.binread('./db/seed/step_copy_artifacts/files/putit_test.file'))
step.tasks.physical_files << PhysicalFile.create!(name: 'main.yml', content: File.binread('./db/seed/step_copy_artifacts/tasks/main.yml'))
step.templates.physical_files << PhysicalFile.create!(name: 'putit_test.conf.j2', content: File.binread('./db/seed/step_copy_artifacts/templates/putit_test.conf.j2'))
step.vars.physical_files << PhysicalFile.create!(name: 'main.yml', content: File.binread('./db/seed/step_copy_artifacts/vars/main.yml'))
