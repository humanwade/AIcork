from __future__ import annotations

import os
import smtplib
from email.message import EmailMessage


def send_verification_email(to_email: str, code: str) -> None:
    """
    Send a verification code email using SMTP.

    This function is intentionally simple and uses Gmail SMTP by default.
    For production, consider replacing this with a provider such as
    SendGrid, AWS SES, or Resend.
    """

    smtp_host = os.getenv("SMTP_HOST", "smtp.gmail.com")
    smtp_port = int(os.getenv("SMTP_PORT", "587"))
    username = os.getenv("MAIL_USERNAME")
    password = os.getenv("MAIL_PASSWORD")
    mail_from = os.getenv("MAIL_FROM") or username

    if not username or not password or not mail_from:
        raise RuntimeError(
            "Email settings are not configured. "
            "Please set MAIL_USERNAME, MAIL_PASSWORD, and MAIL_FROM."
        )

    msg = EmailMessage()
    msg["Subject"] = "Corkey Email Verification Code"
    msg["From"] = mail_from
    msg["To"] = to_email
    msg.set_content(
        f"Your Corkey verification code is: {code}\n\n"
        "This code will expire in a few minutes. "
        "If you did not request this, you can ignore this email."
    )

    with smtplib.SMTP(smtp_host, smtp_port) as server:
        server.ehlo()
        server.starttls()
        server.ehlo()
        server.login(username, password)
        server.send_message(msg)

