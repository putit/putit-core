describe 'JiraController Change' do
  let (:issue_uri) do
    'https://dev-jira.putit.lan/rest/api/2/issue/10208'
  end

  it 'should create Change' do
    VCR.use_cassette('jira-create-change', record: :new_episodes) do
      Release.create!(name: 'Q32017')

      post '/integration/jira/change', create_change_payload, 'CONTENT_TYPE': 'application/json'

      expect(last_response.status).to eq 204

      ro = ReleaseOrder.find_by_name('First deployment')
      expect(ro).to be
      expect(ro.start_date.year).to eq 2017
      expect(ro.start_date.month).to eq 8
      expect(ro.start_date.day).to eq 7
      expect(ro.end_date.year).to eq 2017
      expect(ro.end_date.month).to eq 8
      expect(ro.end_date.day).to eq 31
      expect(ro.metadata['jira_issue_uri']).to eq 'https://dev-jira.putit.lan/rest/api/2/issue/10208'
      expect(ro.metadata['jira_issue_id']).to eq '10208'
      expect(ro.metadata['jira_issue_key']).to eq 'PUTR-44'
      expect(ro.metadata['jira_approvers_field_name']).to eq 'customfield_10200'

      r = Release.find_by_name('Q32017')
      expect(r.release_orders.first).to eq ro
    end
  end

  it 'should gather approvals for Change' do
    VCR.use_cassette('jira-gather-approvals-for-change', record: :new_episodes) do
      r = Release.create!(name: 'Q32017')
      ReleaseOrder.create!(name: 'First deployment') do |ro|
        ro.metadata['jira_approvers_field_name'] = 'customfield_10200'
        ro.metadata['jira_issue_uri'] = 'https://dev-jira.putit.lan/rest/api/2/issue/10208'
        ro.release_id = r.id
      end

      post '/integration/jira/change', gather_approvals_transition_payload, 'CONTENT_TYPE': 'application/json'

      expect(last_response.status).to eq 204

      ro = ReleaseOrder.find_by_name('First deployment')
      expect(ro.metadata['jira_approved_transition_id']).to eq '31'
      expect(ro.approvals.length).to eq 2
      expect(ro.waiting_for_approvals?).to be true
    end
  end

  it 'should update JIRA\'s ticket state to "Approved"' do
    VCR.use_cassette('send-approved-transition', record: :new_episodes) do
      ro = ReleaseOrder.create!(name: 'First deployment') do |ro|
        ro.metadata['jira_approvers_field_name'] = 'customfield_10200'
        ro.metadata['jira_issue_uri'] = issue_uri
        ro.metadata['jira_approved_transition_id'] = '31'
      end

      ro.waiting_for_approvals!
      ro.approved!

      expect(
        a_request(:post, issue_uri.sub('https', 'http') + '/transitions')
          .with(body: { "transition": { "id": 31 } }, headers: { 'Content-Type' => 'application/json' })
      ).to have_been_made
    end
  end

  describe 'Execute' do
    let (:r) do
      Release.create!(name: 'Q32017')
    end

    before :each do
      ReleaseOrder.create!(name: 'First deployment') do |ro|
        ro.metadata['jira_approvers_field_name'] = 'customfield_10200'
        ro.metadata['jira_issue_uri'] = 'https://dev-jira.putit.lan/rest/api/2/issue/10208'
        ro.release_id = r.id
      end

      allow_any_instance_of(MakePlaybookService).to receive(:make_playbook!).and_return(true)

      allow_any_instance_of(RunPlaybookService).to receive(:run!) do |service|
        service.instance_variable_get('@release_order').in_deployment!
      end

      allow_any_instance_of(ArchivePlaybookService).to receive(:run!).and_return(true)
    end

    it 'should execute Release Order' do
      VCR.use_cassette('execute-change-in-deployment', record: :new_episodes) do
        post '/integration/jira/change', execute_transition_payload, 'CONTENT_TYPE': 'application/json'

        expect(last_response.status).to eq 204

        ro = ReleaseOrder.find_by_name('First deployment')

        expect(ro.in_deployment?).to be true
      end
    end

    it 'should update JIRA\'s ticket state to "Success"' do
      VCR.use_cassette('execute-change-in-deployment', record: :new_episodes) do
        ro = ReleaseOrder.find_by_name('First deployment')
        ro.metadata['jira_success_transition_id'] = '51'
        ro.save!

        ro.deployed!

        expect(
          a_request(:post, issue_uri.sub('https', 'http') + '/transitions')
            .with(body: { "transition": { "id": 51 } }, headers: { 'Content-Type' => 'application/json' })
        ).to have_been_made
      end
    end

    it 'should update JIRA\'s ticket state to "Failure"' do
      VCR.use_cassette('execute-change-in-deployment', record: :new_episodes) do
        ro = ReleaseOrder.find_by_name('First deployment')
        ro.metadata['jira_failure_transition_id'] = '61'
        ro.save!

        ro.failed!

        expect(
          a_request(:post, issue_uri.sub('https', 'http') + '/transitions')
            .with(body: { "transition": { "id": 61 } }, headers: { 'Content-Type' => 'application/json' })
        ).to have_been_made
      end
    end
  end

  private

  def create_change_payload
    <<~END
      {
          "timestamp": 1501839767595,
          "webhookEvent": "jira:issue_created",
          "issue_event_type_name": "issue_created",
          "user": {
              "self": "https://dev-jira.putit.lan/rest/api/2/user?username=mwolsza",
              "name": "mwolsza",
              "key": "mwolsza",
              "emailAddress": "mateusz@putit.io",
              "avatarUrls": {
                  "48x48": "https://secure.gravatar.com/avatar/fb732785ed74f07a2480587cdc44e89c?d=mm&s=48",
                  "24x24": "https://secure.gravatar.com/avatar/fb732785ed74f07a2480587cdc44e89c?d=mm&s=24",
                  "16x16": "https://secure.gravatar.com/avatar/fb732785ed74f07a2480587cdc44e89c?d=mm&s=16",
                  "32x32": "https://secure.gravatar.com/avatar/fb732785ed74f07a2480587cdc44e89c?d=mm&s=32"
              },
              "displayName": "Mateusz Wolsza",
              "active": true,
              "timeZone": "UTC"
          },
          "issue": {
              "id": "10208",
              "self": "https://dev-jira.putit.lan/rest/api/2/issue/10208",
              "key": "PUTR-44",
              "fields": {
                  "issuetype": {
                      "self": "https://dev-jira.putit.lan/rest/api/2/issuetype/10101",
                      "id": "10101",
                      "description": "PUTIT Release order",
                      "iconUrl": "https://dev-jira.putit.lan/secure/viewavatar?size=xsmall&avatarId=10316&avatarType=issuetype",
                      "name": "Change",
                      "subtask": true,
                      "avatarId": 10316
                  },
                  "parent": {
                      "id": "10207",
                      "key": "PUTR-43",
                      "self": "https://dev-jira.putit.lan/rest/api/2/issue/10207",
                      "fields": {
                          "summary": "New Release Q3/2017",
                          "status": {
                              "self": "https://dev-jira.putit.lan/rest/api/2/status/1",
                              "description": "The issue is open and ready for the assignee to start work on it.",
                              "iconUrl": "https://dev-jira.putit.lan/images/icons/statuses/open.png",
                              "name": "Open",
                              "id": "1",
                              "statusCategory": {
                                  "self": "https://dev-jira.putit.lan/rest/api/2/statuscategory/2",
                                  "id": 2,
                                  "key": "new",
                                  "colorName": "blue-gray",
                                  "name": "To Do"
                              }
                          },
                          "priority": {
                              "self": "https://dev-jira.putit.lan/rest/api/2/priority/3",
                              "iconUrl": "https://dev-jira.putit.lan/images/icons/priorities/medium.svg",
                              "name": "Medium",
                              "id": "3"
                          },
                          "issuetype": {
                              "self": "https://dev-jira.putit.lan/rest/api/2/issuetype/10100",
                              "id": "10100",
                              "description": "PUTIT Release",
                              "iconUrl": "https://dev-jira.putit.lan/secure/viewavatar?size=xsmall&avatarId=10300&avatarType=issuetype",
                              "name": "Release",
                              "subtask": false,
                              "avatarId": 10300
                          }
                      }
                  },
                  "components": [],
                  "timespent": null,
                  "timeoriginalestimate": null,
                  "description": null,
                  "project": {
                      "self": "https://dev-jira.putit.lan/rest/api/2/project/10200",
                      "id": "10200",
                      "key": "PUTR",
                      "name": "PUTIT_RELEASES",
                      "avatarUrls": {
                          "48x48": "https://dev-jira.putit.lan/secure/projectavatar?pid=10200&avatarId=10325",
                          "24x24": "https://dev-jira.putit.lan/secure/projectavatar?size=small&pid=10200&avatarId=10325",
                          "16x16": "https://dev-jira.putit.lan/secure/projectavatar?size=xsmall&pid=10200&avatarId=10325",
                          "32x32": "https://dev-jira.putit.lan/secure/projectavatar?size=medium&pid=10200&avatarId=10325"
                      }
                  },
                  "fixVersions": [],
                  "aggregatetimespent": null,
                  "resolution": null,
                  "timetracking": {},
                  "customfield_10005": "0|i0003z:",
                  "attachment": [],
                  "aggregatetimeestimate": null,
                  "resolutiondate": null,
                  "workratio": -1,
                  "summary": "First deployment",
                  "lastViewed": null,
                  "watches": {
                      "self": "https://dev-jira.putit.lan/rest/api/2/issue/PUTR-44/watchers",
                      "watchCount": 0,
                      "isWatching": false
                  },
                  "creator": {
                      "self": "https://dev-jira.putit.lan/rest/api/2/user?username=mwolsza",
                      "name": "mwolsza",
                      "key": "mwolsza",
                      "emailAddress": "mateusz@putit.io",
                      "avatarUrls": {
                          "48x48": "https://secure.gravatar.com/avatar/fb732785ed74f07a2480587cdc44e89c?d=mm&s=48",
                          "24x24": "https://secure.gravatar.com/avatar/fb732785ed74f07a2480587cdc44e89c?d=mm&s=24",
                          "16x16": "https://secure.gravatar.com/avatar/fb732785ed74f07a2480587cdc44e89c?d=mm&s=16",
                          "32x32": "https://secure.gravatar.com/avatar/fb732785ed74f07a2480587cdc44e89c?d=mm&s=32"
                      },
                      "displayName": "Mateusz Wolsza",
                      "active": true,
                      "timeZone": "UTC"
                  },
                  "subtasks": [],
                  "created": "2017-08-04T09:42:47.564+0000",
                  "reporter": {
                      "self": "https://dev-jira.putit.lan/rest/api/2/user?username=mwolsza",
                      "name": "mwolsza",
                      "key": "mwolsza",
                      "emailAddress": "mateusz@putit.io",
                      "avatarUrls": {
                          "48x48": "https://secure.gravatar.com/avatar/fb732785ed74f07a2480587cdc44e89c?d=mm&s=48",
                          "24x24": "https://secure.gravatar.com/avatar/fb732785ed74f07a2480587cdc44e89c?d=mm&s=24",
                          "16x16": "https://secure.gravatar.com/avatar/fb732785ed74f07a2480587cdc44e89c?d=mm&s=16",
                          "32x32": "https://secure.gravatar.com/avatar/fb732785ed74f07a2480587cdc44e89c?d=mm&s=32"
                      },
                      "displayName": "Mateusz Wolsza",
                      "active": true,
                      "timeZone": "UTC"
                  },
                  "customfield_10000": null,
                  "aggregateprogress": {
                      "progress": 0,
                      "total": 0
                  },
                  "priority": {
                      "self": "https://dev-jira.putit.lan/rest/api/2/priority/3",
                      "iconUrl": "https://dev-jira.putit.lan/images/icons/priorities/medium.svg",
                      "name": "Medium",
                      "id": "3"
                  },
                  "customfield_10100": null,
                  "customfield_10200": [{
                      "self": "https://dev-jira.putit.lan/rest/api/2/user?username=mwolsza",
                      "name": "mwolsza",
                      "key": "mwolsza",
                      "emailAddress": "mateusz@putit.io",
                      "avatarUrls": {
                          "48x48": "https://secure.gravatar.com/avatar/fb732785ed74f07a2480587cdc44e89c?d=mm&s=48",
                          "24x24": "https://secure.gravatar.com/avatar/fb732785ed74f07a2480587cdc44e89c?d=mm&s=24",
                          "16x16": "https://secure.gravatar.com/avatar/fb732785ed74f07a2480587cdc44e89c?d=mm&s=16",
                          "32x32": "https://secure.gravatar.com/avatar/fb732785ed74f07a2480587cdc44e89c?d=mm&s=32"
                      },
                      "displayName": "Mateusz Wolsza",
                      "active": true,
                      "timeZone": "UTC"
                  }, {
                      "self": "https://dev-jira.putit.lan/rest/api/2/user?username=pskowron",
                      "name": "pskowron",
                      "key": "pskowron",
                      "emailAddress": "skowpio@gmail.com",
                      "avatarUrls": {
                          "48x48": "https://secure.gravatar.com/avatar/b6a13c0c109f7d9f610f504f64678e99?d=mm&s=48",
                          "24x24": "https://secure.gravatar.com/avatar/b6a13c0c109f7d9f610f504f64678e99?d=mm&s=24",
                          "16x16": "https://secure.gravatar.com/avatar/b6a13c0c109f7d9f610f504f64678e99?d=mm&s=16",
                          "32x32": "https://secure.gravatar.com/avatar/b6a13c0c109f7d9f610f504f64678e99?d=mm&s=32"
                      },
                      "displayName": "Piotr Skowron",
                      "active": true,
                      "timeZone": "UTC"
                  }],
                  "customfield_10201": "2017-08-07",
                  "customfield_10202": "2017-08-31",
                  "labels": [],
                  "customfield_10004": null,
                  "environment": null,
                  "timeestimate": null,
                  "aggregatetimeoriginalestimate": null,
                  "versions": [],
                  "duedate": null,
                  "progress": {
                      "progress": 0,
                      "total": 0
                  },
                  "comment": {
                      "comments": [],
                      "maxResults": 0,
                      "total": 0,
                      "startAt": 0
                  },
                  "issuelinks": [],
                  "votes": {
                      "self": "https://dev-jira.putit.lan/rest/api/2/issue/PUTR-44/votes",
                      "votes": 0,
                      "hasVoted": false
                  },
                  "worklog": {
                      "startAt": 0,
                      "maxResults": 20,
                      "total": 0,
                      "worklogs": []
                  },
                  "assignee": null,
                  "updated": "2017-08-04T09:42:47.564+0000",
                  "status": {
                      "self": "https://dev-jira.putit.lan/rest/api/2/status/10100",
                      "description": "Initial status for Change in PUTIT",
                      "iconUrl": "https://dev-jira.putit.lan/images/icons/statuses/generic.png",
                      "name": "Working",
                      "id": "10100",
                      "statusCategory": {
                          "self": "https://dev-jira.putit.lan/rest/api/2/statuscategory/2",
                          "id": 2,
                          "key": "new",
                          "colorName": "blue-gray",
                          "name": "To Do"
                      }
                  }
              }
          }
      }
    END
  end

  def gather_approvals_transition_payload
    <<~END
      {
          "transition": {
              "workflowId": 10212,
              "workflowName": "Change Workflow",
              "transitionId": 11,
              "transitionName": "Gather approvals",
              "from_status": "Working",
              "to_status": "Waiting for approvals"
          },
          "comment": "",
          "user": {
              "self": "https://dev-jira.putit.lan/rest/api/2/user?username=mwolsza",
              "name": "mwolsza",
              "key": "mwolsza",
              "emailAddress": "mateusz@putit.io",
              "avatarUrls": {
                  "48x48": "https://secure.gravatar.com/avatar/fb732785ed74f07a2480587cdc44e89c?d=mm&s=48",
                  "24x24": "https://secure.gravatar.com/avatar/fb732785ed74f07a2480587cdc44e89c?d=mm&s=24",
                  "16x16": "https://secure.gravatar.com/avatar/fb732785ed74f07a2480587cdc44e89c?d=mm&s=16",
                  "32x32": "https://secure.gravatar.com/avatar/fb732785ed74f07a2480587cdc44e89c?d=mm&s=32"
              },
              "displayName": "Mateusz Wolsza",
              "active": true,
              "timeZone": "UTC"
          },
          "issue": {
              "id": "10208",
              "self": "https://dev-jira.putit.lan/rest/api/2/issue/10208",
              "key": "PUTR-44",
              "fields": {
                  "issuetype": {
                      "self": "https://dev-jira.putit.lan/rest/api/2/issuetype/10101",
                      "id": "10101",
                      "description": "PUTIT Release order",
                      "iconUrl": "https://dev-jira.putit.lan/secure/viewavatar?size=xsmall&avatarId=10316&avatarType=issuetype",
                      "name": "Change",
                      "subtask": true,
                      "avatarId": 10316
                  },
                  "parent": {
                      "id": "10207",
                      "key": "PUTR-43",
                      "self": "https://dev-jira.putit.lan/rest/api/2/issue/10207",
                      "fields": {
                          "summary": "New Release Q3/2017",
                          "status": {
                              "self": "https://dev-jira.putit.lan/rest/api/2/status/1",
                              "description": "The issue is open and ready for the assignee to start work on it.",
                              "iconUrl": "https://dev-jira.putit.lan/images/icons/statuses/open.png",
                              "name": "Open",
                              "id": "1",
                              "statusCategory": {
                                  "self": "https://dev-jira.putit.lan/rest/api/2/statuscategory/2",
                                  "id": 2,
                                  "key": "new",
                                  "colorName": "blue-gray",
                                  "name": "To Do"
                              }
                          },
                          "priority": {
                              "self": "https://dev-jira.putit.lan/rest/api/2/priority/3",
                              "iconUrl": "https://dev-jira.putit.lan/images/icons/priorities/medium.svg",
                              "name": "Medium",
                              "id": "3"
                          },
                          "issuetype": {
                              "self": "https://dev-jira.putit.lan/rest/api/2/issuetype/10100",
                              "id": "10100",
                              "description": "PUTIT Release",
                              "iconUrl": "https://dev-jira.putit.lan/secure/viewavatar?size=xsmall&avatarId=10300&avatarType=issuetype",
                              "name": "Release",
                              "subtask": false,
                              "avatarId": 10300
                          }
                      }
                  },
                  "components": [],
                  "timespent": null,
                  "timeoriginalestimate": null,
                  "description": null,
                  "project": {
                      "self": "https://dev-jira.putit.lan/rest/api/2/project/10200",
                      "id": "10200",
                      "key": "PUTR",
                      "name": "PUTIT_RELEASES",
                      "avatarUrls": {
                          "48x48": "https://dev-jira.putit.lan/secure/projectavatar?pid=10200&avatarId=10325",
                          "24x24": "https://dev-jira.putit.lan/secure/projectavatar?size=small&pid=10200&avatarId=10325",
                          "16x16": "https://dev-jira.putit.lan/secure/projectavatar?size=xsmall&pid=10200&avatarId=10325",
                          "32x32": "https://dev-jira.putit.lan/secure/projectavatar?size=medium&pid=10200&avatarId=10325"
                      }
                  },
                  "fixVersions": [],
                  "aggregatetimespent": null,
                  "resolution": null,
                  "timetracking": {},
                  "customfield_10005": "0|i0003z:",
                  "attachment": [],
                  "aggregatetimeestimate": null,
                  "resolutiondate": null,
                  "workratio": -1,
                  "summary": "First deployment",
                  "lastViewed": "2017-08-05T11:45:10.939+0000",
                  "watches": {
                      "self": "https://dev-jira.putit.lan/rest/api/2/issue/PUTR-44/watchers",
                      "watchCount": 1,
                      "isWatching": true
                  },
                  "creator": {
                      "self": "https://dev-jira.putit.lan/rest/api/2/user?username=mwolsza",
                      "name": "mwolsza",
                      "key": "mwolsza",
                      "emailAddress": "mateusz@putit.io",
                      "avatarUrls": {
                          "48x48": "https://secure.gravatar.com/avatar/fb732785ed74f07a2480587cdc44e89c?d=mm&s=48",
                          "24x24": "https://secure.gravatar.com/avatar/fb732785ed74f07a2480587cdc44e89c?d=mm&s=24",
                          "16x16": "https://secure.gravatar.com/avatar/fb732785ed74f07a2480587cdc44e89c?d=mm&s=16",
                          "32x32": "https://secure.gravatar.com/avatar/fb732785ed74f07a2480587cdc44e89c?d=mm&s=32"
                      },
                      "displayName": "Mateusz Wolsza",
                      "active": true,
                      "timeZone": "UTC"
                  },
                  "subtasks": [],
                  "created": "2017-08-04T09:42:47.564+0000",
                  "reporter": {
                      "self": "https://dev-jira.putit.lan/rest/api/2/user?username=mwolsza",
                      "name": "mwolsza",
                      "key": "mwolsza",
                      "emailAddress": "mateusz@putit.io",
                      "avatarUrls": {
                          "48x48": "https://secure.gravatar.com/avatar/fb732785ed74f07a2480587cdc44e89c?d=mm&s=48",
                          "24x24": "https://secure.gravatar.com/avatar/fb732785ed74f07a2480587cdc44e89c?d=mm&s=24",
                          "16x16": "https://secure.gravatar.com/avatar/fb732785ed74f07a2480587cdc44e89c?d=mm&s=16",
                          "32x32": "https://secure.gravatar.com/avatar/fb732785ed74f07a2480587cdc44e89c?d=mm&s=32"
                      },
                      "displayName": "Mateusz Wolsza",
                      "active": true,
                      "timeZone": "UTC"
                  },
                  "customfield_10000": null,
                  "aggregateprogress": {
                      "progress": 0,
                      "total": 0
                  },
                  "priority": {
                      "self": "https://dev-jira.putit.lan/rest/api/2/priority/3",
                      "iconUrl": "https://dev-jira.putit.lan/images/icons/priorities/medium.svg",
                      "name": "Medium",
                      "id": "3"
                  },
                  "customfield_10100": null,
                  "customfield_10200": [{
                      "self": "https://dev-jira.putit.lan/rest/api/2/user?username=mwolsza",
                      "name": "mwolsza",
                      "key": "mwolsza",
                      "emailAddress": "mateusz@putit.io",
                      "avatarUrls": {
                          "48x48": "https://secure.gravatar.com/avatar/fb732785ed74f07a2480587cdc44e89c?d=mm&s=48",
                          "24x24": "https://secure.gravatar.com/avatar/fb732785ed74f07a2480587cdc44e89c?d=mm&s=24",
                          "16x16": "https://secure.gravatar.com/avatar/fb732785ed74f07a2480587cdc44e89c?d=mm&s=16",
                          "32x32": "https://secure.gravatar.com/avatar/fb732785ed74f07a2480587cdc44e89c?d=mm&s=32"
                      },
                      "displayName": "Mateusz Wolsza",
                      "active": true,
                      "timeZone": "UTC"
                  }, {
                      "self": "https://dev-jira.putit.lan/rest/api/2/user?username=pskowron",
                      "name": "pskowron",
                      "key": "pskowron",
                      "emailAddress": "skowpio@gmail.com",
                      "avatarUrls": {
                          "48x48": "https://secure.gravatar.com/avatar/b6a13c0c109f7d9f610f504f64678e99?d=mm&s=48",
                          "24x24": "https://secure.gravatar.com/avatar/b6a13c0c109f7d9f610f504f64678e99?d=mm&s=24",
                          "16x16": "https://secure.gravatar.com/avatar/b6a13c0c109f7d9f610f504f64678e99?d=mm&s=16",
                          "32x32": "https://secure.gravatar.com/avatar/b6a13c0c109f7d9f610f504f64678e99?d=mm&s=32"
                      },
                      "displayName": "Piotr Skowron",
                      "active": true,
                      "timeZone": "UTC"
                  }],
                  "labels": [],
                  "customfield_10004": null,
                  "environment": null,
                  "timeestimate": null,
                  "aggregatetimeoriginalestimate": null,
                  "versions": [],
                  "duedate": null,
                  "progress": {
                      "progress": 0,
                      "total": 0
                  },
                  "comment": {
                      "comments": [],
                      "maxResults": 0,
                      "total": 0,
                      "startAt": 0
                  },
                  "issuelinks": [],
                  "votes": {
                      "self": "https://dev-jira.putit.lan/rest/api/2/issue/PUTR-44/votes",
                      "votes": 0,
                      "hasVoted": false
                  },
                  "worklog": {
                      "startAt": 0,
                      "maxResults": 20,
                      "total": 0,
                      "worklogs": []
                  },
                  "assignee": null,
                  "updated": "2017-08-05T11:44:10.737+0000",
                  "status": {
                      "self": "https://dev-jira.putit.lan/rest/api/2/status/10100",
                      "description": "Initial status for Change in PUTIT",
                      "iconUrl": "https://dev-jira.putit.lan/images/icons/statuses/generic.png",
                      "name": "Working",
                      "id": "10100",
                      "statusCategory": {
                          "self": "https://dev-jira.putit.lan/rest/api/2/statuscategory/2",
                          "id": 2,
                          "key": "new",
                          "colorName": "blue-gray",
                          "name": "To Do"
                      }
                  }
              }
          },
          "timestamp": 1501933510944
      }
    END
  end

  def execute_transition_payload
    <<~END
      {
          "transition": {
              "workflowId": 10212,
              "workflowName": "Change Workflow",
              "transitionId": 41,
              "transitionName": "Execute",
              "from_status": "Approved",
              "to_status": "In Deployment"
          },
          "comment": "",
          "user": {
              "self": "https://dev-jira.putit.lan/rest/api/2/user?username=mwolsza",
              "name": "mwolsza",
              "key": "mwolsza",
              "emailAddress": "mateusz@putit.io",
              "avatarUrls": {
                  "48x48": "https://secure.gravatar.com/avatar/fb732785ed74f07a2480587cdc44e89c?d=mm&s=48",
                  "24x24": "https://secure.gravatar.com/avatar/fb732785ed74f07a2480587cdc44e89c?d=mm&s=24",
                  "16x16": "https://secure.gravatar.com/avatar/fb732785ed74f07a2480587cdc44e89c?d=mm&s=16",
                  "32x32": "https://secure.gravatar.com/avatar/fb732785ed74f07a2480587cdc44e89c?d=mm&s=32"
              },
              "displayName": "Mateusz Wolsza",
              "active": true,
              "timeZone": "UTC"
          },
          "issue": {
              "id": "10208",
              "self": "https://dev-jira.putit.lan/rest/api/2/issue/10208",
              "key": "PUTR-44",
              "fields": {
                  "issuetype": {
                      "self": "https://dev-jira.putit.lan/rest/api/2/issuetype/10101",
                      "id": "10101",
                      "description": "PUTIT Release order",
                      "iconUrl": "https://dev-jira.putit.lan/secure/viewavatar?size=xsmall&avatarId=10316&avatarType=issuetype",
                      "name": "Change",
                      "subtask": true,
                      "avatarId": 10316
                  },
                  "parent": {
                      "id": "10207",
                      "key": "PUTR-43",
                      "self": "https://dev-jira.putit.lan/rest/api/2/issue/10207",
                      "fields": {
                          "summary": "New Release Q3/2017",
                          "status": {
                              "self": "https://dev-jira.putit.lan/rest/api/2/status/1",
                              "description": "The issue is open and ready for the assignee to start work on it.",
                              "iconUrl": "https://dev-jira.putit.lan/images/icons/statuses/open.png",
                              "name": "Open",
                              "id": "1",
                              "statusCategory": {
                                  "self": "https://dev-jira.putit.lan/rest/api/2/statuscategory/2",
                                  "id": 2,
                                  "key": "new",
                                  "colorName": "blue-gray",
                                  "name": "To Do"
                              }
                          },
                          "priority": {
                              "self": "https://dev-jira.putit.lan/rest/api/2/priority/3",
                              "iconUrl": "https://dev-jira.putit.lan/images/icons/priorities/medium.svg",
                              "name": "Medium",
                              "id": "3"
                          },
                          "issuetype": {
                              "self": "https://dev-jira.putit.lan/rest/api/2/issuetype/10100",
                              "id": "10100",
                              "description": "PUTIT Release",
                              "iconUrl": "https://dev-jira.putit.lan/secure/viewavatar?size=xsmall&avatarId=10300&avatarType=issuetype",
                              "name": "Release",
                              "subtask": false,
                              "avatarId": 10300
                          }
                      }
                  },
                  "components": [],
                  "description": null,
                  "project": {
                      "self": "https://dev-jira.putit.lan/rest/api/2/project/10200",
                      "id": "10200",
                      "key": "PUTR",
                      "name": "PUTIT_RELEASES",
                      "avatarUrls": {
                          "48x48": "https://dev-jira.putit.lan/secure/projectavatar?pid=10200&avatarId=10325",
                          "24x24": "https://dev-jira.putit.lan/secure/projectavatar?size=small&pid=10200&avatarId=10325",
                          "16x16": "https://dev-jira.putit.lan/secure/projectavatar?size=xsmall&pid=10200&avatarId=10325",
                          "32x32": "https://dev-jira.putit.lan/secure/projectavatar?size=medium&pid=10200&avatarId=10325"
                      }
                  },
                  "fixVersions": [],
                  "customfield_10005": "0|i0003z:",
                  "attachment": [],
                  "resolutiondate": null,
                  "workratio": -1,
                  "summary": "First deployment",
                  "lastViewed": "2017-08-10T10:13:53.891+0000",
                  "watches": {
                      "self": "https://dev-jira.putit.lan/rest/api/2/issue/PUTR-44/watchers",
                      "watchCount": 1,
                      "isWatching": true
                  },
                  "creator": {
                      "self": "https://dev-jira.putit.lan/rest/api/2/user?username=mwolsza",
                      "name": "mwolsza",
                      "key": "mwolsza",
                      "emailAddress": "mateusz@putit.io",
                      "avatarUrls": {
                          "48x48": "https://secure.gravatar.com/avatar/fb732785ed74f07a2480587cdc44e89c?d=mm&s=48",
                          "24x24": "https://secure.gravatar.com/avatar/fb732785ed74f07a2480587cdc44e89c?d=mm&s=24",
                          "16x16": "https://secure.gravatar.com/avatar/fb732785ed74f07a2480587cdc44e89c?d=mm&s=16",
                          "32x32": "https://secure.gravatar.com/avatar/fb732785ed74f07a2480587cdc44e89c?d=mm&s=32"
                      },
                      "displayName": "Mateusz Wolsza",
                      "active": true,
                      "timeZone": "UTC"
                  },
                  "subtasks": [],
                  "created": "2017-08-04T09:42:47.564+0000",
                  "reporter": {
                      "self": "https://dev-jira.putit.lan/rest/api/2/user?username=mwolsza",
                      "name": "mwolsza",
                      "key": "mwolsza",
                      "emailAddress": "mateusz@putit.io",
                      "avatarUrls": {
                          "48x48": "https://secure.gravatar.com/avatar/fb732785ed74f07a2480587cdc44e89c?d=mm&s=48",
                          "24x24": "https://secure.gravatar.com/avatar/fb732785ed74f07a2480587cdc44e89c?d=mm&s=24",
                          "16x16": "https://secure.gravatar.com/avatar/fb732785ed74f07a2480587cdc44e89c?d=mm&s=16",
                          "32x32": "https://secure.gravatar.com/avatar/fb732785ed74f07a2480587cdc44e89c?d=mm&s=32"
                      },
                      "displayName": "Mateusz Wolsza",
                      "active": true,
                      "timeZone": "UTC"
                  },
                  "customfield_10000": null,
                  "customfield_10100": null,
                  "customfield_10200": [{
                      "self": "https://dev-jira.putit.lan/rest/api/2/user?username=mwolsza",
                      "name": "mwolsza",
                      "key": "mwolsza",
                      "emailAddress": "mateusz@putit.io",
                      "avatarUrls": {
                          "48x48": "https://secure.gravatar.com/avatar/fb732785ed74f07a2480587cdc44e89c?d=mm&s=48",
                          "24x24": "https://secure.gravatar.com/avatar/fb732785ed74f07a2480587cdc44e89c?d=mm&s=24",
                          "16x16": "https://secure.gravatar.com/avatar/fb732785ed74f07a2480587cdc44e89c?d=mm&s=16",
                          "32x32": "https://secure.gravatar.com/avatar/fb732785ed74f07a2480587cdc44e89c?d=mm&s=32"
                      },
                      "displayName": "Mateusz Wolsza",
                      "active": true,
                      "timeZone": "UTC"
                  }, {
                      "self": "https://dev-jira.putit.lan/rest/api/2/user?username=pskowron",
                      "name": "pskowron",
                      "key": "pskowron",
                      "emailAddress": "skowpio@gmail.com",
                      "avatarUrls": {
                          "48x48": "https://secure.gravatar.com/avatar/b6a13c0c109f7d9f610f504f64678e99?d=mm&s=48",
                          "24x24": "https://secure.gravatar.com/avatar/b6a13c0c109f7d9f610f504f64678e99?d=mm&s=24",
                          "16x16": "https://secure.gravatar.com/avatar/b6a13c0c109f7d9f610f504f64678e99?d=mm&s=16",
                          "32x32": "https://secure.gravatar.com/avatar/b6a13c0c109f7d9f610f504f64678e99?d=mm&s=32"
                      },
                      "displayName": "Piotr Skowron",
                      "active": true,
                      "timeZone": "UTC"
                  }],
                  "customfield_10201": "2017-08-07",
                  "customfield_10202": "2017-08-31",
                  "customfield_10004": null,
                  "environment": null,
                  "versions": [],
                  "duedate": null,
                  "comment": {
                      "comments": [],
                      "maxResults": 0,
                      "total": 0,
                      "startAt": 0
                  },
                  "issuelinks": [],
                  "votes": {
                      "self": "https://dev-jira.putit.lan/rest/api/2/issue/PUTR-44/votes",
                      "votes": 0,
                      "hasVoted": false
                  },
                  "assignee": null,
                  "updated": "2017-08-10T09:53:05.807+0000",
                  "status": {
                      "self": "https://dev-jira.putit.lan/rest/api/2/status/10102",
                      "description": "Change is Approved and it can be deployed.",
                      "iconUrl": "https://dev-jira.putit.lan/images/icons/statuses/generic.png",
                      "name": "Approved",
                      "id": "10102",
                      "statusCategory": {
                          "self": "https://dev-jira.putit.lan/rest/api/2/statuscategory/4",
                          "id": 4,
                          "key": "indeterminate",
                          "colorName": "yellow",
                          "name": "In Progress"
                      }
                  }
              }
          },
          "timestamp": 1502360033897
      }
    END
  end
end
