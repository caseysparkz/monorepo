#!/usr/bin/env python3
# Author:       Casey Sparks
# Date:         October 05, 2023
# Description:
"""Python Lambda function for website contact page."""

from __future__ import annotations

from json import dumps, loads
from logging import StreamHandler, getLogger
from os import getenv
from sys import modules
from textwrap import dedent
from typing import TYPE_CHECKING

from boto3 import client

if TYPE_CHECKING or "pytest" in modules:
    from types_boto3_ses import type_defs

LOG = getLogger(__name__)

LOG.addHandler(StreamHandler())
LOG.setLevel(10)  # DEBUG


def send_email(data: dict[str, str]) -> type_defs.SendEmailResponseTypeDef:
    """Send an email via AWS SES.

    Args:
        data:   Dict containing `REQUIRED_KEYS'.

    Returns:
                The SES client response.
    """
    ses_response = client("ses", region_name=getenv("AWS_REGION", "us-west-2")).send_email(
        Source=str(getenv("DEFAULT_SENDER")),
        Destination={"ToAddresses": [str(getenv("DEFAULT_RECIPIENT"))]},
        Message={
            "Subject": {
                "Charset": "UTF-8",
                "Data": "Contact Form Response",
            },
            "Body": {
                "Text": {
                    "Charset": "UTF-8",
                    "Data": dedent(f"""
                        From: {data["senderName"]}
                        Email: {data["senderEmail"]}
                        Content: {data["message"]}
                    """).strip("\n"),
                }
            },
        },
    )

    LOG.debug(ses_response)

    return ses_response  # type: ignore[no-any-return]


def lambda_handler(event: dict[str, str], context: dict[str, str] | None = None) -> dict[str, object]:
    """Default function for Lambda functions.

    Args:
        event:   The Lamba event to handle.
        context: Context for said Lambda event.

    Returns:
        Dictionary containing the Lambda response.
    """
    LOG.debug("Event: %s", event)
    LOG.debug("Context: %s", context)

    lambda_response = {
        "statusCode": 200,
        "headers": {"Content-Type": "application/json"},
        "body": dumps(
            {
                "Success": True,
                "SesResponse": send_email(loads(event["body"])),
            }
        ),
    }

    LOG.debug(lambda_response)

    return lambda_response
