SECRET_KEY = 'Ly048vj1TXU9YSLTpOLl0wfY6EgNXCUv7VJiwoc5xZfJWlAsq1L2M+fV'
SQLALCHEMY_DATABASE_URI='mysql://superset_user:superset@mysql:3306/superset'

# Flask-WTF flag for CSRF
WTF_CSRF_ENABLED = True
# Add endpoints that need to be exempt from CSRF protection
WTF_CSRF_EXEMPT_LIST = []
# A CSRF token that expires in 1 year
WTF_CSRF_TIME_LIMIT = 60 * 60 * 24 * 365

FEATURE_FLAGS = {"ALERT_REPORTS": True, "DASHBOARD_RBAC": True}

