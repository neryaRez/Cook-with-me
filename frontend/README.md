# Cook With Me - Frontend

The frontend for **Cook With Me**, an AI-powered recipe sharing platform. Built
with React, Vite, Tailwind CSS, and React Router.

This folder contains **UI code only**. It has no database access, no
server-side code, and no direct calls to OpenAI - all of that will live in a
separate `/backend` service.

## Tech stack

- React (JavaScript, no TypeScript)
- Vite
- Tailwind CSS v4
- React Router

## Getting started

```bash
npm install
npm run dev
```

The app runs at `http://localhost:5173`.

Other scripts:

```bash
npm run build    # production build
npm run preview  # preview the production build locally
npm run lint     # run ESLint
```

## Project structure

```
src/
  components/   Reusable UI building blocks (cards, nav, chat, icons...)
  layouts/      Page layout wrappers (e.g. MainLayout: navbar + footer + Robo Chef)
  pages/        Route-level pages (Home, Recipes feed, Recipe details, Create, Robo Chef)
  router/       React Router route definitions
  services/     API layer - the only place that talks to the backend (api.js)
  data/         Mock data and static config (recipes, categories, tags, chat replies)
  utils/        Small shared helper functions
```

## API layer

All data access goes through `src/services/api.js`, which exports:

- `getRecipes()`
- `getRecipeById(id)`
- `createRecipe(data)`
- `createComment(recipeId, data)`
- `askRoboChef(data)`

Today these functions resolve mock data from `src/data/`. Once a backend is
available, set `VITE_API_BASE_URL` (see `.env.example`) and the same functions
will call the real REST endpoints instead - no other code needs to change:

```
GET    /api/recipes
GET    /api/recipes/:id
POST   /api/recipes
POST   /api/recipes/:id/comments
POST   /api/ai/ask
```

`api.js` is the **only** file allowed to read `VITE_API_BASE_URL` or call
`fetch`. Components and pages must always go through these service functions.

## Categories & tags

Recipes use a small, fixed set of main categories (`src/data/categories.js`):
Meat, Dairy, Vegetarian, Vegan, Fish, Asian, Italian, Desserts, Quick Meals.

Optional descriptive tags (Breakfast, Lunch, Dinner, Spicy, Healthy, High
Protein, 30 Minutes, Kosher, Gluten Free) can be attached to any recipe
regardless of category.

## Backend integration (future)

This frontend is designed to be deployed independently (its own Docker image,
its own EKS deployment) from the backend, which will own:

- the recipe/comment database (external, non-AWS)
- the OpenAI integration for Robo Chef
- all secrets, via Kubernetes Secrets

No secrets are stored in this project.
