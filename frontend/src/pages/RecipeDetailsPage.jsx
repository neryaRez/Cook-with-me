import { useEffect, useState } from 'react'
import { Link, useParams } from 'react-router-dom'
import { getRecipeById } from '../services/api.js'
import Loader from '../components/Loader.jsx'
import CommentSection from '../components/CommentSection.jsx'
import { getTotalTime } from '../utils/recipe.js'
import {
  ArrowLeftIcon,
  ClockIcon,
  FlameIcon,
  StarIcon,
  UsersIcon,
} from '../components/icons.jsx'

export default function RecipeDetailsPage() {
  const { id } = useParams()
  const [recipe, setRecipe] = useState(null)
  const [isLoading, setIsLoading] = useState(true)
  const [error, setError] = useState(null)
  const [checkedIngredients, setCheckedIngredients] = useState([])

  useEffect(() => {
    let isMounted = true
    setIsLoading(true)
    setError(null)

    getRecipeById(id)
      .then((data) => {
        if (isMounted) setRecipe(data)
      })
      .catch(() => {
        if (isMounted) setError('We could not find that recipe.')
      })
      .finally(() => {
        if (isMounted) setIsLoading(false)
      })

    return () => {
      isMounted = false
    }
  }, [id])

  function toggleIngredient(item) {
    setCheckedIngredients((prev) =>
      prev.includes(item) ? prev.filter((entry) => entry !== item) : [...prev, item]
    )
  }

  function handleCommentAdded(newComment) {
    setRecipe((prev) => (prev ? { ...prev, comments: [...prev.comments, newComment] } : prev))
  }

  if (isLoading) {
    return <Loader label="Loading recipe..." />
  }

  if (error || !recipe) {
    return (
      <div className="mx-auto max-w-2xl px-4 py-20 text-center">
        <p className="font-display text-2xl font-bold text-cream">Recipe not found</p>
        <p className="mt-2 text-sm text-muted">{error ?? 'This recipe may have been removed.'}</p>
        <Link
          to="/recipes"
          className="mt-6 inline-flex items-center gap-2 rounded-full bg-ember px-5 py-2.5 text-sm font-semibold text-cream"
        >
          <ArrowLeftIcon className="h-4 w-4" />
          Back to recipes
        </Link>
      </div>
    )
  }

  const totalTime = getTotalTime(recipe)

  return (
    <div>
      <div className="relative h-72 w-full overflow-hidden sm:h-96">
        <img src={recipe.image} alt={recipe.title} className="h-full w-full object-cover" />
        <div className="absolute inset-0 bg-gradient-to-t from-ink via-ink/40 to-ink/10" />
        <div className="absolute inset-x-0 bottom-0 mx-auto w-full max-w-7xl px-4 pb-6 sm:px-6 lg:px-8">
          <Link
            to="/recipes"
            className="mb-4 inline-flex items-center gap-1.5 rounded-full border border-border-subtle/70 bg-ink/60 px-3.5 py-1.5 text-sm font-medium text-cream backdrop-blur-sm transition-colors hover:border-ember/40"
          >
            <ArrowLeftIcon className="h-4 w-4" />
            Back to recipes
          </Link>
          <span className="inline-block rounded-full bg-ember px-3 py-1 text-xs font-semibold uppercase tracking-wide text-cream">
            {recipe.category}
          </span>
          <h1 className="mt-3 font-display text-3xl font-extrabold text-cream sm:text-4xl lg:text-5xl">
            {recipe.title}
          </h1>
        </div>
      </div>

      <div className="mx-auto max-w-7xl px-4 py-10 sm:px-6 lg:px-8">
        <div className="flex flex-wrap items-center gap-3">
          <div className="flex items-center gap-2 rounded-full border border-border-subtle/70 bg-card px-4 py-2 text-sm text-muted">
            <img
              src={recipe.author.avatar}
              alt={recipe.author.name}
              className="h-6 w-6 rounded-full object-cover"
            />
            <span className="text-cream">{recipe.author.name}</span>
          </div>
          <div className="flex items-center gap-1.5 rounded-full border border-border-subtle/70 bg-card px-4 py-2 text-sm text-muted">
            <ClockIcon className="h-4 w-4" />
            {totalTime} min total
          </div>
          <div className="flex items-center gap-1.5 rounded-full border border-border-subtle/70 bg-card px-4 py-2 text-sm text-muted">
            <UsersIcon className="h-4 w-4" />
            Serves {recipe.servings}
          </div>
          <div className="flex items-center gap-1.5 rounded-full border border-border-subtle/70 bg-card px-4 py-2 text-sm text-muted">
            <FlameIcon className="h-4 w-4" />
            {recipe.difficulty}
          </div>
          <div className="flex items-center gap-1.5 rounded-full border border-border-subtle/70 bg-card px-4 py-2 text-sm text-amber">
            <StarIcon className="h-4 w-4" />
            {recipe.rating.toFixed(1)}
          </div>
        </div>

        <p className="mt-6 max-w-3xl text-base leading-relaxed text-muted">{recipe.description}</p>

        <div className="mt-4 flex flex-wrap gap-2">
          {recipe.tags.map((tag) => (
            <span
              key={tag}
              className="rounded-full border border-border-subtle/70 bg-surface px-3 py-1 text-xs text-muted"
            >
              #{tag}
            </span>
          ))}
        </div>

        <div className="mt-10 grid grid-cols-1 gap-10 lg:grid-cols-3">
          <div className="lg:col-span-1">
            <div className="rounded-2xl border border-border-subtle/70 bg-card p-6">
              <h2 className="font-display text-lg font-bold text-cream">Ingredients</h2>
              <ul className="mt-4 space-y-3">
                {recipe.ingredients.map((ingredient) => {
                  const key = `${ingredient.item}-${ingredient.amount}`
                  const checked = checkedIngredients.includes(key)

                  return (
                    <li key={key}>
                      <label className="flex cursor-pointer items-start gap-3 text-sm">
                        <input
                          type="checkbox"
                          checked={checked}
                          onChange={() => toggleIngredient(key)}
                          className="mt-0.5 h-4 w-4 shrink-0 rounded border-border-subtle bg-surface accent-ember"
                        />
                        <span className={checked ? 'text-muted line-through' : 'text-cream'}>
                          <span className="font-medium">{ingredient.amount}</span> {ingredient.item}
                        </span>
                      </label>
                    </li>
                  )
                })}
              </ul>
            </div>
          </div>

          <div className="lg:col-span-2">
            <div className="rounded-2xl border border-border-subtle/70 bg-card p-6">
              <h2 className="font-display text-lg font-bold text-cream">Instructions</h2>
              <ol className="mt-4 space-y-5">
                {recipe.steps.map((step, index) => (
                  <li key={index} className="flex gap-4">
                    <span className="flex h-8 w-8 shrink-0 items-center justify-center rounded-full bg-ember/15 font-display text-sm font-bold text-ember-light">
                      {index + 1}
                    </span>
                    <p className="pt-1 text-sm leading-relaxed text-muted">{step}</p>
                  </li>
                ))}
              </ol>
            </div>

            <div className="mt-10 rounded-2xl border border-border-subtle/70 bg-card p-6">
              <CommentSection
                recipeId={recipe.id}
                comments={recipe.comments}
                onCommentAdded={handleCommentAdded}
              />
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}
