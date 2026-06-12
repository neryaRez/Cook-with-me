from flask import Flask
from flask_cors import CORS

from .routes.ai import ai_bp
from .routes.health import health_bp
from .routes.recipes import recipes_bp


def create_app():
    app = Flask(__name__)
    CORS(app)

    app.register_blueprint(health_bp)
    app.register_blueprint(recipes_bp)
    app.register_blueprint(ai_bp)

    return app
