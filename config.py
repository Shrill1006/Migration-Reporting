import os 
from types import SimpleNamespace


class Config(object):
    MAIL_HOST = os.environ.get('MAIL_HOST') or 'onmsg.tsl.telus.com'
    BTO_OPENSHIFT_EMAIL = 'dlBTOOpenshiftSupport@telus.com (BTO Openshift Support)'
    EMAIL_SUBJECT = 'Migration Report Results'
    EMAIL_CONTENT = "Below you will find that attatched results of the migration script."