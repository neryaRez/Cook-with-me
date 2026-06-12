from flask import Blueprint, jsonify, request

from ..services.openai_service import ask_robo_chef

ai_bp = Blueprint("ai", __name__, url_prefix="/api/ai")


@ai_bp.route("/ask", methods=["POST"])
def ask():
    payload = request.get_json(silent=True) or {}
    message = (payload.get("message") or "").strip()
    if not message:
        return jsonify({"error": "message is required"}), 400

    context = payload.get("context") or {}

    try:
        answer = ask_robo_chef(message, context)
    except Exception as exc:  # OpenAI request failed
        return jsonify({"error": f"Robo Chef is currently unavailable: {exc}"}), 502

    return jsonify({"data": {"answer": answer}})
