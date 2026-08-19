import json

# Identifiants de démo, en dur uniquement parce qu'il n'y a pas de vraie base
# utilisateurs derrière ce projet de formation. Dans un vrai projet, ce serait
# vérifié contre une base de données ou un service d'authentification.
VALID_USERNAME = "demo"
VALID_PASSWORD = "infoline2026"


def handler(event, context):
    body = json.loads(event.get("body") or "{}")
    username = body.get("username")
    password = body.get("password")

    if username == VALID_USERNAME and password == VALID_PASSWORD:
        return {
            "statusCode": 200,
            "body": json.dumps({"message": "Login OK", "service": "infoline-login"}),
        }

    return {
        "statusCode": 401,
        "body": json.dumps({"message": "Identifiants invalides", "service": "infoline-login"}),
    }
