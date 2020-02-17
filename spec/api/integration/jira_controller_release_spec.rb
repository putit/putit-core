describe 'JiraController release' do
  it 'should create Release' do
    VCR.use_cassette('jira-create') do
      post '/integration/jira/release', create_issue_payload, 'CONTENT_TYPE': 'application/json'

      expect(last_response.status).to eq 204

      release = Release.find_by_name('Q32017')
      expect(release).to be
      expect(release.metadata['jira_issue_uri']).to eq 'https://dev-jira.putit.lan/rest/api/2/issue/10207'
      expect(release.metadata['jira_issue_id']).to eq '10207'
      expect(release.metadata['jira_issue_key']).to eq 'PUTR-43'
    end
  end

  it 'close Release' do
    VCR.use_cassette('jira-transition-close') do
      Release.create!(name: 'Q32017')
      post '/integration/jira/release', close_transition_payload, 'CONTENT_TYPE': 'application/json'

      expect(last_response.status).to eq 204

      release = Release.find_by_name('Q32017')
      expect(release.status).to eq 'closed'
    end
  end

  it 'reopen Release' do
    VCR.use_cassette('jira-transition-reopen') do
      r = Release.create!(name: 'Q32017')
      r.closed!

      post '/integration/jira/release', reopen_transition_payload, 'CONTENT_TYPE': 'application/json'

      expect(last_response.status).to eq 204

      release = Release.find_by_name('Q32017')
      expect(release.status).to eq 'open'
    end
  end

  private

  def create_issue_payload
    <<~END
      {
          "timestamp": 1501760558782,
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
              "id": "10207",
              "self": "https://dev-jira.putit.lan/rest/api/2/issue/10207",
              "key": "PUTR-43",
              "fields": {
                  "issuetype": {
                      "self": "https://dev-jira.putit.lan/rest/api/2/issuetype/10100",
                      "id": "10100",
                      "description": "PUTIT Release",
                      "iconUrl": "https://dev-jira.putit.lan/secure/viewavatar?size=xsmall&avatarId=10300&avatarType=issuetype",
                      "name": "Release",
                      "subtask": false,
                      "avatarId": 10300
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
                  "customfield_10005": "0|i0003r:",
                  "attachment": [],
                  "aggregatetimeestimate": null,
                  "resolutiondate": null,
                  "workratio": -1,
                  "summary": "New Release Q3/2017",
                  "lastViewed": null,
                  "watches": {
                      "self": "https://dev-jira.putit.lan/rest/api/2/issue/PUTR-43/watchers",
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
                  "created": "2017-08-03T11:42:38.751+0000",
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
                  "customfield_10100": "Q32017",
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
                      "self": "https://dev-jira.putit.lan/rest/api/2/issue/PUTR-43/votes",
                      "votes": 0,
                      "hasVoted": false
                  },
                  "worklog": {
                      "startAt": 0,
                      "maxResults": 20,
                      "total": 0,
                      "worklogs": []
                  },
                  "assignee": {
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
                  "updated": "2017-08-03T11:42:38.751+0000",
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
                  }
              }
          }
      }
    END
  end

  def close_transition_payload
    <<~END
      {
          "transition": {
              "workflowId": 10211,
              "workflowName": "Release Workflow",
              "transitionId": 11,
              "transitionName": "Close release",
              "from_status": "Open",
              "to_status": "Closed"
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
              "id": "10207",
              "self": "https://dev-jira.putit.lan/rest/api/2/issue/10207",
              "key": "PUTR-43",
              "fields": {
                  "issuetype": {
                      "self": "https://dev-jira.putit.lan/rest/api/2/issuetype/10100",
                      "id": "10100",
                      "description": "PUTIT Release",
                      "iconUrl": "https://dev-jira.putit.lan/secure/viewavatar?size=xsmall&avatarId=10300&avatarType=issuetype",
                      "name": "Release",
                      "subtask": false,
                      "avatarId": 10300
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
                  "customfield_10005": "0|i0003r:",
                  "attachment": [],
                  "aggregatetimeestimate": null,
                  "resolutiondate": null,
                  "workratio": -1,
                  "summary": "New Release Q3/2017",
                  "lastViewed": "2017-08-03T12:36:38.221+0000",
                  "watches": {
                      "self": "https://dev-jira.putit.lan/rest/api/2/issue/PUTR-43/watchers",
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
                  "created": "2017-08-03T11:42:38.751+0000",
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
                  "customfield_10100": "Q32017",
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
                      "self": "https://dev-jira.putit.lan/rest/api/2/issue/PUTR-43/votes",
                      "votes": 0,
                      "hasVoted": false
                  },
                  "worklog": {
                      "startAt": 0,
                      "maxResults": 20,
                      "total": 0,
                      "worklogs": []
                  },
                  "assignee": {
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
                  "updated": "2017-08-03T11:42:38.751+0000",
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
                  }
              }
          },
          "timestamp": 1501763798226
      }
    END
  end

  def reopen_transition_payload
    <<~END
      {
          "transition": {
              "workflowId": 10211,
              "workflowName": "Release Workflow",
              "transitionId": 21,
              "transitionName": "Reopen Release",
              "from_status": "Closed",
              "to_status": "Open"
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
              "id": "10207",
              "self": "https://dev-jira.putit.lan/rest/api/2/issue/10207",
              "key": "PUTR-43",
              "fields": {
                  "issuetype": {
                      "self": "https://dev-jira.putit.lan/rest/api/2/issuetype/10100",
                      "id": "10100",
                      "description": "PUTIT Release",
                      "iconUrl": "https://dev-jira.putit.lan/secure/viewavatar?size=xsmall&avatarId=10300&avatarType=issuetype",
                      "name": "Release",
                      "subtask": false,
                      "avatarId": 10300
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
                  "customfield_10005": "0|i0003r:",
                  "attachment": [],
                  "aggregatetimeestimate": null,
                  "resolutiondate": null,
                  "workratio": -1,
                  "summary": "New Release Q32017",
                  "lastViewed": "2017-08-03T14:18:39.796+0000",
                  "watches": {
                      "self": "https://dev-jira.putit.lan/rest/api/2/issue/PUTR-43/watchers",
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
                  "created": "2017-08-03T11:42:38.751+0000",
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
                  "customfield_10100": "Q32017",
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
                      "self": "https://dev-jira.putit.lan/rest/api/2/issue/PUTR-43/votes",
                      "votes": 0,
                      "hasVoted": false
                  },
                  "worklog": {
                      "startAt": 0,
                      "maxResults": 20,
                      "total": 0,
                      "worklogs": []
                  },
                  "assignee": {
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
                  "updated": "2017-08-03T12:36:38.264+0000",
                  "status": {
                      "self": "https://dev-jira.putit.lan/rest/api/2/status/6",
                      "description": "The issue is considered finished, the resolution is correct. Issues which are closed can be reopened.",
                      "iconUrl": "https://dev-jira.putit.lan/images/icons/statuses/closed.png",
                      "name": "Closed",
                      "id": "6",
                      "statusCategory": {
                          "self": "https://dev-jira.putit.lan/rest/api/2/statuscategory/3",
                          "id": 3,
                          "key": "done",
                          "colorName": "green",
                          "name": "Done"
                      }
                  }
              }
          },
          "timestamp": 1501769919804
      }
    END
  end
end
