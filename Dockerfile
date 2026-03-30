FROM mattermost/mattermost-team-edition:release-10.12

USER root

# Replace only the server binary to keep everything else identical.
COPY --chown=mattermost:mattermost bin/mattermost /mattermost/bin/mattermost

USER 2000:2000
