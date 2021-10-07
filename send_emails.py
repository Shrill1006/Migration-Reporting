import smtplib as smtp
from typing import List
from config import Config
from email import encoders
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from email.mime.base import MIMEBase


FILENAME = 'out.csv'
FILEPATH = './out.csv'


def get_addresses(file: str):
    emails = []
    with open(file, mode='r', encoding='utf-8') as addresses:
        for address in addresses: 
            emails.append(address)
    return emails


def send_email(recipients: List, subject: str, body: str, from_email=Config.BTO_OPENSHIFT_EMAIL):
    try:
        msg = MIMEMultipart()
        msg['Subject'] = subject
        msg['From'] = from_email
        msg['To'] = ', '.join(recipients)
        msg.attach(MIMEText(body, 'plain'))
        attachment = MIMEBase('application', "octet-stream")
        attachment.set_payload(open(FILEPATH, "rb").read())
        encoders.encode_base64(attachment)
        attachment.add_header('Content-Disposition', 'attachment', filename=FILENAME)
        msg.attach(attachment)
        server = smtp.SMTP(host=Config.MAIL_HOST)
        server.send_message(msg)
        server.quit()
    except Exception as exp:
        print(str(exp))


emails = get_addresses('emails.txt')
send_email(emails, "Migration Check Results", "Attached to this email are the results of the migration script.")
