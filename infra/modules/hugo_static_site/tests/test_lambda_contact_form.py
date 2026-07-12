#!/usr/bin/env python3
# Author:       Casey Sparks
# Date:         October 05, 2023
# Description:
"""Python Lambda function for website contact page."""

import os
from collections.abc import Generator
from json import dumps
from unittest import mock

import boto3
import pytest
from moto import mock_aws
from types_boto3_ses import SESClient

from .. import lambda_contact_form  # noqa:TID252

AWS_REGION = "us-west-2"
DEFAULT_SENDER = "test@test.com"
MESSAGE = "Test email body."
SENDER_NAME = "John Doe"
EVENT = {
    "body": dumps(
        {
            "senderEmail": DEFAULT_SENDER,
            "senderName": SENDER_NAME,
            "message": MESSAGE,
        }
    )
}


@pytest.fixture(autouse=True)
def set_environment(monkeypatch: pytest.MonkeyPatch) -> Generator[None]:
    """Set env vars expected by lambda handler."""
    with mock.patch.dict(os.environ, clear=True):
        monkeypatch.setenv("DEFAULT_SENDER", DEFAULT_SENDER)
        monkeypatch.setenv("DEFAULT_RECIPIENT", "testrecipient@test.com")

        yield


@pytest.fixture(autouse=True)
def set_ses_client() -> Generator[SESClient]:
    """Create a mock SES client."""
    with mock_aws():
        client = boto3.client("ses", region_name=AWS_REGION)

        client.verify_email_identity(EmailAddress=DEFAULT_SENDER)

        yield client


def test_send_email() -> None:
    """Send an email via AWS SES.

    Args:
        data:   Dict containing `REQUIRED_KEYS'.

    Returns:
                The SES client response.
    """
    assert lambda_contact_form.send_email(
        {
            "senderEmail": "test@test.com",
            "senderName": "John Doe",
            "message": "Test email body.",
        }
    )


def test_lambda_handler() -> None:
    """Default function for Lambda functions.

    Args:
        event:   The Lamba event to handle.
        context: Context for said Lambda event.

    Returns:
        Dictionary containing the Lambda response.
    """
    response = lambda_contact_form.lambda_handler(
        event={
            "body": dumps(
                {
                    "senderName": "John Doe",
                    "senderEmail": "test@test.com",
                    "message": "Test email body.",
                }
            )
        },
        context={},
    )

    assert isinstance(response, dict)
