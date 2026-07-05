/*
Name:           contactForm.js
Date:           December 20, 2023
Author:         Casey Sparks
Description:    Sends a POST request to ${lambda_url}.
*/

/*global $, alert, document, location*/

async function submitEvent(e) {
    "use strict";
    e.preventDefault();

    const response = await fetch(
        "${lambda_url}",
        {
            method: "POST",
            mode: "cors",
            cache: "no-cache",
            credentials: "same-origin",
            headers: {"Content-Type": "application/json"},
            redirect: "follow",
            referrerPolicy: "no-referrer",
            body: JSON.stringify({
                senderName: $("#sender_name").val(),
                senderEmail: $("#sender_email").val(),
                message: $("#message").val(),
            }),
        }
    );

    if (response.status === 200) {
        alert("Success");
        document.getElementById("contact-form").reset();
        location.reload();
    } else {
        alert("Error");
    }

    return response.json();
}
