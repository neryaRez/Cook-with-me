"""Recipe endpoints.

When DATABASE_URL is not configured (config.USE_DB is False), this module
serves and mutates an in-memory list of mock recipes so the API is fully
usable for local development and for the frontend. When an external MySQL
database is configured later, these handlers can be switched to use
db.get_session() and real models instead of _RECIPES.
"""

from datetime import date

from flask import Blueprint, jsonify, request

from .. import config
from ..db import get_session
from ..models import Recipe

recipes_bp = Blueprint("recipes", __name__, url_prefix="/api/recipes")

_RECIPES = [
    {
        "id": "1",
        "title": "Creamy Garlic Parmesan Pasta",
        "description": "A silky pasta tossed in a roasted garlic and parmesan cream sauce.",
        "image": "https://images.unsplash.com/photo-1551183053-bf91a1d81141?auto=format&fit=crop&w=1200&q=80",
        "category": "Italian",
        "cuisine": "Italian",
        "difficulty": "Easy",
        "prepTime": 10,
        "cookTime": 20,
        "servings": 4,
        "rating": 4.8,
        "author": {"name": "Maria Lopez", "avatar": "https://i.pravatar.cc/100?img=47"},
        "tags": ["Dinner"],
        "ingredients": [
            {"item": "Spaghetti", "amount": "400g"},
            {"item": "Garlic cloves, minced", "amount": "6"},
            {"item": "Heavy cream", "amount": "1 cup"},
            {"item": "Parmesan, grated", "amount": "1 cup"},
        ],
        "steps": [
            "Cook the spaghetti until al dente.",
            "Saute garlic in butter, then add cream and simmer.",
            "Whisk in parmesan until smooth and toss with the pasta.",
        ],
        "comments": [],
    },
    {
        "id": "2",
        "title": "Spicy Korean Beef Tacos",
        "description": "Bulgogi-style beef in warm tortillas with pickled veggies and gochujang crema.",
        "image": "https://images.unsplash.com/photo-1565299585323-38d6b0865b47?auto=format&fit=crop&w=1200&q=80",
        "category": "Meat",
        "cuisine": "Fusion",
        "difficulty": "Medium",
        "prepTime": 25,
        "cookTime": 15,
        "servings": 4,
        "rating": 4.9,
        "author": {"name": "Jae Park", "avatar": "https://i.pravatar.cc/100?img=33"},
        "tags": ["Dinner", "Spicy"],
        "ingredients": [
            {"item": "Flank steak, thinly sliced", "amount": "500g"},
            {"item": "Soy sauce", "amount": "4 tbsp"},
            {"item": "Corn tortillas", "amount": "8 small"},
            {"item": "Gochujang", "amount": "1 tbsp"},
        ],
        "steps": [
            "Marinate the steak in soy sauce and garlic.",
            "Sear the beef until caramelized.",
            "Fill tortillas with beef, pickled veggies, and gochujang crema.",
        ],
        "comments": [],
    },
    {
        "id": "3",
        "title": "Rainbow Buddha Bowl",
        "description": "Roasted vegetables, quinoa, and crispy chickpeas with tahini dressing.",
        "image": "https://images.unsplash.com/photo-1512621776951-a57141f2eefd?auto=format&fit=crop&w=1200&q=80",
        "category": "Vegan",
        "cuisine": "Mediterranean",
        "difficulty": "Easy",
        "prepTime": 15,
        "cookTime": 25,
        "servings": 2,
        "rating": 4.7,
        "author": {"name": "Aiko Tanaka", "avatar": "https://i.pravatar.cc/100?img=5"},
        "tags": ["Healthy", "Vegan"],
        "ingredients": [
            {"item": "Quinoa", "amount": "1 cup"},
            {"item": "Chickpeas", "amount": "1 can"},
            {"item": "Sweet potato", "amount": "1 large"},
            {"item": "Tahini", "amount": "2 tbsp"},
        ],
        "steps": [
            "Roast the sweet potato and chickpeas until crispy.",
            "Cook the quinoa according to package instructions.",
            "Assemble the bowl and drizzle with tahini dressing.",
        ],
        "comments": [],
    },
    {
        "id": "4",
        "title": "Classic New York Cheesecake",
        "description": "A dense, velvety cheesecake with a buttery graham cracker crust.",
        "image": "https://images.unsplash.com/photo-1533134242443-d4fd215305ad?auto=format&fit=crop&w=1200&q=80",
        "category": "Desserts",
        "cuisine": "American",
        "difficulty": "Hard",
        "prepTime": 30,
        "cookTime": 75,
        "servings": 10,
        "rating": 4.9,
        "author": {"name": "Emily Carter", "avatar": "https://i.pravatar.cc/100?img=20"},
        "tags": ["Desserts"],
        "ingredients": [
            {"item": "Cream cheese", "amount": "900g"},
            {"item": "Graham crackers", "amount": "200g"},
            {"item": "Sugar", "amount": "1 cup"},
            {"item": "Eggs", "amount": "4"},
        ],
        "steps": [
            "Press the graham cracker crust into a springform pan.",
            "Beat cream cheese, sugar, and eggs until smooth.",
            "Bake low and slow, then chill overnight before serving.",
        ],
        "comments": [],
    },
    {
        "id": "5",
        "title": "One-Pan Lemon Herb Salmon",
        "description": "Flaky salmon roasted with lemon, herbs, and a side of vegetables.",
        "image": "https://images.unsplash.com/photo-1467003909585-2f8a72700288?auto=format&fit=crop&w=1200&q=80",
        "category": "Fish",
        "cuisine": "Mediterranean",
        "difficulty": "Easy",
        "prepTime": 10,
        "cookTime": 20,
        "servings": 2,
        "rating": 4.6,
        "author": {"name": "Tom Chen", "avatar": "https://i.pravatar.cc/100?img=12"},
        "tags": ["Healthy", "30 Minutes", "Quick Meals"],
        "ingredients": [
            {"item": "Salmon fillets", "amount": "2"},
            {"item": "Lemon", "amount": "1"},
            {"item": "Olive oil", "amount": "2 tbsp"},
            {"item": "Mixed herbs", "amount": "1 tbsp"},
        ],
        "steps": [
            "Place salmon and vegetables on a sheet pan.",
            "Drizzle with olive oil, lemon, and herbs.",
            "Roast until the salmon is cooked through.",
        ],
        "comments": [],
    },
    {
        "id": "6",
        "title": "15-Minute Garlic Sesame Noodles",
        "description": "Quick stir-fried noodles in a garlicky sesame-soy sauce.",
        "image": "https://images.unsplash.com/photo-1612929633738-8fe44f7ec841?auto=format&fit=crop&w=1200&q=80",
        "category": "Quick Meals",
        "cuisine": "Asian",
        "difficulty": "Easy",
        "prepTime": 5,
        "cookTime": 10,
        "servings": 2,
        "rating": 4.5,
        "author": {"name": "Wei Zhang", "avatar": "https://i.pravatar.cc/100?img=8"},
        "tags": ["Quick Meals", "Asian"],
        "ingredients": [
            {"item": "Noodles", "amount": "200g"},
            {"item": "Garlic, minced", "amount": "3 cloves"},
            {"item": "Soy sauce", "amount": "3 tbsp"},
            {"item": "Sesame oil", "amount": "1 tbsp"},
        ],
        "steps": [
            "Cook the noodles and drain.",
            "Stir-fry garlic in sesame oil until fragrant.",
            "Toss the noodles with the sauce and serve.",
        ],
        "comments": [],
    },
]

def _serialize_recipe(recipe):
    return {
        "id": str(recipe.id),
        "title": recipe.title,
        "description": recipe.description,
        "image": recipe.image,
        "category": recipe.category,
        "cuisine": recipe.cuisine,
        "difficulty": recipe.difficulty,
        "prepTime": recipe.prep_time,
        "cookTime": recipe.cook_time,
        "servings": recipe.servings,
        "rating": recipe.rating,
        "author": {
            "name": recipe.author_name,
            "avatar": recipe.author_avatar,
        },
        "tags": recipe.tags or [],
        "ingredients": recipe.ingredients or [],
        "steps": recipe.steps or [],
        "comments": recipe.comments or [],
    }


def _find_mock_recipe(recipe_id):
    return next((recipe for recipe in _RECIPES if recipe["id"] == str(recipe_id)), None)


def _next_mock_id():
    return str(max((int(recipe["id"]) for recipe in _RECIPES), default=0) + 1)


@recipes_bp.route("", methods=["GET"])
def list_recipes():
    if config.USE_DB:
        session = get_session()
        try:
            recipes = session.query(Recipe).order_by(Recipe.id.desc()).all()
            return jsonify({"data": [_serialize_recipe(recipe) for recipe in recipes]})
        finally:
            session.close()

    return jsonify({"data": _RECIPES})


@recipes_bp.route("/<recipe_id>", methods=["GET"])
def get_recipe(recipe_id):
    if config.USE_DB:
        session = get_session()
        try:
            recipe = session.get(Recipe, int(recipe_id))
            if recipe is None:
                return jsonify({"error": "Recipe not found"}), 404
            return jsonify({"data": _serialize_recipe(recipe)})
        finally:
            session.close()

    recipe = _find_mock_recipe(recipe_id)
    if recipe is None:
        return jsonify({"error": "Recipe not found"}), 404
    return jsonify({"data": recipe})


@recipes_bp.route("", methods=["POST"])
def create_recipe():
    payload = request.get_json(silent=True) or {}

    if not payload.get("title") or not payload.get("description"):
        return jsonify({"error": "title and description are required"}), 400

    if config.USE_DB:
        session = get_session()
        try:
            author = payload.get("author") or {}

            recipe = Recipe(
                title=payload["title"],
                description=payload["description"],
                image=payload.get("image", ""),
                category=payload.get("category", "Quick Meals"),
                cuisine=payload.get("cuisine", "Fusion"),
                difficulty=payload.get("difficulty", "Easy"),
                prep_time=payload.get("prepTime", 0),
                cook_time=payload.get("cookTime", 0),
                servings=payload.get("servings", 1),
                rating=0,
                author_name=author.get("name", "Guest Chef"),
                author_avatar=author.get("avatar", "https://i.pravatar.cc/100?img=1"),
                tags=payload.get("tags", []),
                ingredients=payload.get("ingredients", []),
                steps=payload.get("steps", []),
                comments=[],
            )

            session.add(recipe)
            session.commit()
            session.refresh(recipe)

            return jsonify({"data": _serialize_recipe(recipe)}), 201
        except Exception:
            session.rollback()
            raise
        finally:
            session.close()

    recipe = {
        "id": _next_mock_id(),
        "title": payload["title"],
        "description": payload["description"],
        "image": payload.get("image", ""),
        "category": payload.get("category", "Quick Meals"),
        "cuisine": payload.get("cuisine", "Fusion"),
        "difficulty": payload.get("difficulty", "Easy"),
        "prepTime": payload.get("prepTime", 0),
        "cookTime": payload.get("cookTime", 0),
        "servings": payload.get("servings", 1),
        "rating": 0,
        "author": {"name": "Guest Chef", "avatar": "https://i.pravatar.cc/100?img=1"},
        "tags": payload.get("tags", []),
        "ingredients": payload.get("ingredients", []),
        "steps": payload.get("steps", []),
        "comments": [],
    }

    _RECIPES.append(recipe)
    return jsonify({"data": recipe}), 201


@recipes_bp.route("/<recipe_id>/comments", methods=["POST"])
def add_comment(recipe_id):
    payload = request.get_json(silent=True) or {}
    text = (payload.get("text") or "").strip()

    if not text:
        return jsonify({"error": "text is required"}), 400

    comment = {
        "id": f"c{date.today().isoformat()}-{recipe_id}",
        "author": payload.get("author", "Guest"),
        "text": text,
        "date": date.today().isoformat(),
    }

    if config.USE_DB:
        session = get_session()
        try:
            recipe = session.get(Recipe, int(recipe_id))
            if recipe is None:
                return jsonify({"error": "Recipe not found"}), 404

            comments = list(recipe.comments or [])
            comment["id"] = f"c{len(comments) + 1}"
            comments.append(comment)

            recipe.comments = comments
            session.commit()

            return jsonify({"data": comment}), 201
        except Exception:
            session.rollback()
            raise
        finally:
            session.close()

    recipe = _find_mock_recipe(recipe_id)
    if recipe is None:
        return jsonify({"error": "Recipe not found"}), 404

    comment["id"] = f"c{len(recipe['comments']) + 1}"
    recipe["comments"].append(comment)

    return jsonify({"data": comment}), 201

@recipes_bp.route("/<recipe_id>", methods=["DELETE"])
def delete_recipe(recipe_id):
    if config.USE_DB:
        session = get_session()
        try:
            recipe = session.get(Recipe, int(recipe_id))
            if recipe is None:
                return jsonify({"error": "Recipe not found"}), 404

            session.delete(recipe)
            session.commit()
            return jsonify({"data": {"deleted": True, "id": str(recipe_id)}})
        except Exception:
            session.rollback()
            raise
        finally:
            session.close()

    recipe = _find_mock_recipe(recipe_id)
    if recipe is None:
        return jsonify({"error": "Recipe not found"}), 404

    _RECIPES.remove(recipe)
    return jsonify({"data": {"deleted": True, "id": str(recipe_id)}})
