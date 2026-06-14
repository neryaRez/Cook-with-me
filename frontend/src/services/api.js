import { mockRecipes } from '../data/mockRecipes'
import { chatKeywordResponses, defaultChatReply } from '../data/mockChatResponses'

// Base URL of the real backend, e.g. https://api.cookwithme.app
// Leave VITE_API_BASE_URL unset to keep running on local mock data.
// This is the ONLY file in the frontend that knows about the backend URL -
// no other component or page should read VITE_API_BASE_URL or call fetch directly.
const API_BASE_URL = import.meta.env.VITE_API_BASE_URL

const MOCK_DELAY_MS = 500

// In-memory copy of the mock recipes so created recipes/comments persist
// for the lifetime of the session without touching the original seed data.
const recipesStore = mockRecipes.map((recipe) => ({
  ...recipe,
  comments: [...recipe.comments],
}))

const delay = (ms) => new Promise((resolve) => setTimeout(resolve, ms))

const generateId = () => `id-${Date.now()}-${Math.floor(Math.random() * 10000)}`

/**
 * Thin wrapper around fetch for talking to the real backend.
 * Used automatically once VITE_API_BASE_URL is configured.
 */
async function request(path, options = {}) {
  const response = await fetch(`${API_BASE_URL}${path}`, {
    headers: { 'Content-Type': 'application/json' },
    ...options,
  })

  if (!response.ok) {
    throw new Error(`Request failed: ${response.status} ${response.statusText}`)
  }

  const json = await response.json()
  return json.data ?? json
}

/**
 * Fetch all recipes.
 * Real endpoint: GET /api/recipes
 */
export async function getRecipes() {
  if (API_BASE_URL) {
    return request('/api/recipes')
  }

  await delay(MOCK_DELAY_MS)
  return recipesStore
}

/**
 * Fetch a single recipe by id.
 * Real endpoint: GET /api/recipes/:id
 */
export async function getRecipeById(id) {
  if (API_BASE_URL) {
    return request(`/api/recipes/${id}`)
  }

  await delay(MOCK_DELAY_MS)
  const recipe = recipesStore.find((item) => item.id === id)

  if (!recipe) {
    throw new Error(`Recipe with id "${id}" not found`)
  }

  return recipe
}

/**
 * Create a new recipe.
 * Real endpoint: POST /api/recipes
 */
export async function createRecipe(data) {
  if (API_BASE_URL) {
    return request('/api/recipes', {
      method: 'POST',
      body: JSON.stringify(data),
    })
  }

  await delay(MOCK_DELAY_MS)

  const newRecipe = {
    id: generateId(),
    rating: 0,
    comments: [],
    author: data.author ?? { name: 'You', avatar: 'https://i.pravatar.cc/100?img=68' },
    ...data,
  }

  recipesStore.unshift(newRecipe)
  return newRecipe
}

/**
 * Add a comment to a recipe.
 * Real endpoint: POST /api/recipes/:id/comments
 */
export async function createComment(recipeId, data) {
  if (API_BASE_URL) {
    return request(`/api/recipes/${recipeId}/comments`, {
      method: 'POST',
      body: JSON.stringify(data),
    })
  }

  await delay(MOCK_DELAY_MS)

  const recipe = recipesStore.find((item) => item.id === recipeId)

  if (!recipe) {
    throw new Error(`Recipe with id "${recipeId}" not found`)
  }

  const newComment = {
    id: generateId(),
    author: data.author ?? 'You',
    text: data.text,
    date: data.date ?? new Date().toISOString().slice(0, 10),
  }

  recipe.comments.push(newComment)
  return newComment
}

/**
 * Ask Robo Chef, the AI cooking assistant, a question.
 * Real endpoint: POST /api/ai/ask
 * The backend (not the frontend) calls OpenAI using a server-side API key.
 */
export async function askRoboChef(data) {
  if (API_BASE_URL) {
    const result = await request('/api/ai/ask', {
      method: 'POST',
      body: JSON.stringify(data),
    })

    return {
      id: generateId(),
      reply: result.answer ?? result.reply ?? 'Robo Chef did not return an answer.',
    }
  }

  await delay(MOCK_DELAY_MS)

  const message = (data.message ?? '').toLowerCase()
  const match = chatKeywordResponses.find((entry) =>
    entry.keywords.some((keyword) => message.includes(keyword))
  )

  return {
    id: generateId(),
    reply: match ? match.reply : defaultChatReply,
  }
}
