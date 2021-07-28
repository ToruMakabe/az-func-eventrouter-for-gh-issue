import json
import logging
from shared import settings

import azure.functions as func
from github import Github, GithubException


def main(event: func.EventGridEvent):
    result = json.dumps({
        'id': event.id,
        'data': event.get_json(),
        'topic': event.topic,
        'subject': event.subject,
        'event_type': event.event_type,
    },
        indent=2
    )

    logging.info('Python EventGrid trigger processed an event: %s', result)

    g = Github(settings.GITHUB_TOKEN)
    repo = g.get_repo(
        settings.GITHUB_REPO_OWNER +
        '/' +
        settings.GITHUB_REPO_NAME
    )

    # Create Issue
    logging.info('Creating an issue.')
    try:
        repo.create_issue(
            title='[Azure Event] ' + event.event_type,
            body='```json\n' + result + '\n```',
            labels=[settings.GITHUB_LABEL],
        )
    except GithubException as e:
        logging.exception(e)
        raise
