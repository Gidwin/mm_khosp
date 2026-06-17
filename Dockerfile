FROM mattermost/mattermost-team-edition:release-10.12

USER root

# Replace the server binary to keep everything else identical.
COPY --chown=mattermost:mattermost bin/mattermost /mattermost/bin/mattermost

# Replace the webapp bundle so frontend changes (e.g. scheduled posts without a
# license) take effect. The base image ships the upstream client, which still
# gates these features behind a license. Built via `cd webapp && make dist`.
COPY --chown=mattermost:mattermost webapp/channels/dist /mattermost/client

USER 2000:2000
