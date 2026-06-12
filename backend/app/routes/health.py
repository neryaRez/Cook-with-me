from flask import Blueprint, jsonify

from .. import config

health_bp = Blueprint("health", __name__)


@health_bp.route("/health", methods=["GET"])
def health():
    return jsonify(
        {
            "status": "ok",
            "db_configured": config.USE_DB,
            "openai_configured": config.USE_OPENAI,
        }
    )
