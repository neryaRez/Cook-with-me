from flask import Flask
from flask_cors import CORS

from . import config
from .db import init_db
from .routes.ai import ai_bp
from .routes.health import health_bp
from .routes.recipes import recipes_bp


def create_app():
    app = Flask(__name__)
    CORS(app)

    app.register_blueprint(health_bp)
    app.register_blueprint(recipes_bp)
    app.register_blueprint(ai_bp)

    if config.USE_DB:
        init_db()

    return app
