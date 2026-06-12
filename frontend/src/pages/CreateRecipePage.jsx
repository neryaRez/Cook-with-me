import { useState } from 'react'
import { Link } from 'react-router-dom'
import { createRecipe } from '../services/api.js'
import { categories, tags as tagOptions } from '../data/categories.js'
import { ChefHatIcon, PlusIcon, CloseIcon } from '../components/icons.jsx'

const DIFFICULTIES = ['Easy', 'Medium', 'Hard']

const EMPTY_INGREDIENT = { item: '', amount: '' }

const initialFormState = {
  title: '',
  description: '',
  image: '',
  category: categories[1],
  cuisine: '',
  difficulty: 'Easy',
  prepTime: '',
  cookTime: '',
  servings: '',
}

export default function CreateRecipePage() {
  const [form, setForm] = useState(initialFormState)
  const [selectedTags, setSelectedTags] = useState([])
  const [ingredients, setIngredients] = useState([{ ...EMPTY_INGREDIENT }])
  const [steps, setSteps] = useState([''])
  const [isSubmitting, setIsSubmitting] = useState(false)
  const [createdRecipe, setCreatedRecipe] = useState(null)
  const [error, setError] = useState(null)

  function updateField(field, value) {
    setForm((prev) => ({ ...prev, [field]: value }))
  }

  function updateIngredient(index, field, value) {
    setIngredients((prev) =>
      prev.map((ingredient, i) => (i === index ? { ...ingredient, [field]: value } : ingredient))
    )
  }

  function addIngredient() {
    setIngredients((prev) => [...prev, { ...EMPTY_INGREDIENT }])
  }

  function removeIngredient(index) {
    setIngredients((prev) => prev.filter((_, i) => i !== index))
  }

  function updateStep(index, value) {
    setSteps((prev) => prev.map((step, i) => (i === index ? value : step)))
  }

  function addStep() {
    setSteps((prev) => [...prev, ''])
  }

  function removeStep(index) {
    setSteps((prev) => prev.filter((_, i) => i !== index))
  }

  function toggleTag(tag) {
    setSelectedTags((prev) =>
      prev.includes(tag) ? prev.filter((entry) => entry !== tag) : [...prev, tag]
    )
  }

  async function handleSubmit(event) {
    event.preventDefault()
    setError(null)

    if (!form.title.trim() || !form.description.trim()) {
      setError('Please add a title and description for your recipe.')
      return
    }

    setIsSubmitting(true)

    try {
      const newRecipe = await createRecipe({
        title: form.title.trim(),
        description: form.description.trim(),
        image:
          form.image.trim() ||
          'https://images.unsplash.com/photo-1495521821757-a1efb6729352?auto=format&fit=crop&w=1200&q=80',
        category: form.category,
        cuisine: form.cuisine.trim() || 'Fusion',
        difficulty: form.difficulty,
        prepTime: Number(form.prepTime) || 0,
        cookTime: Number(form.cookTime) || 0,
        servings: Number(form.servings) || 1,
        tags: selectedTags,
        ingredients: ingredients.filter((ingredient) => ingredient.item.trim()),
        steps: steps.filter((step) => step.trim()),
      })

      setCreatedRecipe(newRecipe)
    } catch {
      setError('Something went wrong while publishing your recipe. Please try again.')
    } finally {
      setIsSubmitting(false)
    }
  }

  function resetForm() {
    setForm(initialFormState)
    setSelectedTags([])
    setIngredients([{ ...EMPTY_INGREDIENT }])
    setSteps([''])
    setCreatedRecipe(null)
  }

  if (createdRecipe) {
    return (
      <div className="mx-auto max-w-2xl px-4 py-20 text-center">
        <span className="mx-auto flex h-16 w-16 items-center justify-center rounded-full bg-ember/15 text-ember-light">
          <ChefHatIcon className="h-8 w-8" />
        </span>
        <h1 className="mt-6 font-display text-3xl font-bold text-cream">Recipe published!</h1>
        <p className="mt-2 text-sm text-muted">
          &ldquo;{createdRecipe.title}&rdquo; is now live in the Cook With Me feed.
        </p>
        <div className="mt-8 flex flex-col items-center justify-center gap-3 sm:flex-row">
          <Link
            to={`/recipes/${createdRecipe.id}`}
            className="flex items-center gap-2 rounded-full bg-ember px-5 py-2.5 text-sm font-semibold text-cream"
          >
            View recipe
          </Link>
          <button
            type="button"
            onClick={resetForm}
            className="flex items-center gap-2 rounded-full border border-border-subtle/70 bg-card px-5 py-2.5 text-sm font-semibold text-cream hover:border-ember/40"
          >
            Create another
          </button>
        </div>
      </div>
    )
  }

  return (
    <div className="mx-auto max-w-3xl px-4 py-10 sm:px-6 lg:px-8">
      <h1 className="font-display text-3xl font-bold text-cream sm:text-4xl">Create a Recipe</h1>
      <p className="mt-2 text-sm text-muted">
        Share your dish with the Cook With Me community. Add ingredients, step-by-step
        instructions, and a photo if you have one.
      </p>

      <form onSubmit={handleSubmit} className="mt-8 space-y-8">
        {error && (
          <p className="rounded-2xl border border-rose-200 bg-rose-50 px-4 py-3 text-sm text-rose-700">
            {error}
          </p>
        )}

        <section className="space-y-4 rounded-2xl border border-border-subtle/70 bg-card p-6">
          <h2 className="font-display text-lg font-bold text-cream">Basics</h2>

          <Field label="Recipe title">
            <input
              type="text"
              value={form.title}
              onChange={(event) => updateField('title', event.target.value)}
              placeholder="e.g. Smoky Chipotle Black Bean Tacos"
              className={inputClass}
            />
          </Field>

          <Field label="Description">
            <textarea
              value={form.description}
              onChange={(event) => updateField('description', event.target.value)}
              placeholder="A short, mouth-watering description of your dish."
              rows={3}
              className={`${inputClass} resize-none`}
            />
          </Field>

          <Field label="Image URL (optional)">
            <input
              type="url"
              value={form.image}
              onChange={(event) => updateField('image', event.target.value)}
              placeholder="https://..."
              className={inputClass}
            />
          </Field>

          <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
            <Field label="Category">
              <select
                value={form.category}
                onChange={(event) => updateField('category', event.target.value)}
                className={inputClass}
              >
                {categories
                  .filter((category) => category !== 'All')
                  .map((category) => (
                    <option key={category} value={category}>
                      {category}
                    </option>
                  ))}
              </select>
            </Field>

            <Field label="Cuisine">
              <input
                type="text"
                value={form.cuisine}
                onChange={(event) => updateField('cuisine', event.target.value)}
                placeholder="e.g. Mexican"
                className={inputClass}
              />
            </Field>
          </div>

          <div className="grid grid-cols-2 gap-4 sm:grid-cols-4">
            <Field label="Difficulty">
              <select
                value={form.difficulty}
                onChange={(event) => updateField('difficulty', event.target.value)}
                className={inputClass}
              >
                {DIFFICULTIES.map((difficulty) => (
                  <option key={difficulty} value={difficulty}>
                    {difficulty}
                  </option>
                ))}
              </select>
            </Field>

            <Field label="Prep (min)">
              <input
                type="number"
                min="0"
                value={form.prepTime}
                onChange={(event) => updateField('prepTime', event.target.value)}
                className={inputClass}
              />
            </Field>

            <Field label="Cook (min)">
              <input
                type="number"
                min="0"
                value={form.cookTime}
                onChange={(event) => updateField('cookTime', event.target.value)}
                className={inputClass}
              />
            </Field>

            <Field label="Servings">
              <input
                type="number"
                min="1"
                value={form.servings}
                onChange={(event) => updateField('servings', event.target.value)}
                className={inputClass}
              />
            </Field>
          </div>

          <div>
            <span className="mb-1.5 block text-sm font-medium text-cream">Tags (optional)</span>
            <div className="flex flex-wrap gap-2">
              {tagOptions.map((tag) => (
                <button
                  key={tag}
                  type="button"
                  onClick={() => toggleTag(tag)}
                  className={`rounded-full border px-3 py-1.5 text-xs font-medium transition-colors ${
                    selectedTags.includes(tag)
                      ? 'border-ember bg-ember text-cream'
                      : 'border-border-subtle/70 bg-surface text-muted hover:border-ember/40 hover:text-cream'
                  }`}
                >
                  {tag}
                </button>
              ))}
            </div>
          </div>
        </section>

        <section className="space-y-4 rounded-2xl border border-border-subtle/70 bg-card p-6">
          <div className="flex items-center justify-between">
            <h2 className="font-display text-lg font-bold text-cream">Ingredients</h2>
            <button type="button" onClick={addIngredient} className={addButtonClass}>
              <PlusIcon className="h-4 w-4" />
              Add ingredient
            </button>
          </div>

          <div className="space-y-3">
            {ingredients.map((ingredient, index) => (
              <div key={index} className="flex items-center gap-2">
                <input
                  type="text"
                  value={ingredient.amount}
                  onChange={(event) => updateIngredient(index, 'amount', event.target.value)}
                  placeholder="Amount"
                  className={`${inputClass} w-28`}
                />
                <input
                  type="text"
                  value={ingredient.item}
                  onChange={(event) => updateIngredient(index, 'item', event.target.value)}
                  placeholder="Ingredient"
                  className={`${inputClass} flex-1`}
                />
                <RemoveButton onClick={() => removeIngredient(index)} disabled={ingredients.length === 1} />
              </div>
            ))}
          </div>
        </section>

        <section className="space-y-4 rounded-2xl border border-border-subtle/70 bg-card p-6">
          <div className="flex items-center justify-between">
            <h2 className="font-display text-lg font-bold text-cream">Instructions</h2>
            <button type="button" onClick={addStep} className={addButtonClass}>
              <PlusIcon className="h-4 w-4" />
              Add step
            </button>
          </div>

          <div className="space-y-3">
            {steps.map((step, index) => (
              <div key={index} className="flex items-start gap-2">
                <span className="mt-2.5 flex h-7 w-7 shrink-0 items-center justify-center rounded-full bg-ember/15 text-xs font-bold text-ember-light">
                  {index + 1}
                </span>
                <textarea
                  value={step}
                  onChange={(event) => updateStep(index, event.target.value)}
                  placeholder={`Describe step ${index + 1}...`}
                  rows={2}
                  className={`${inputClass} flex-1 resize-none`}
                />
                <RemoveButton onClick={() => removeStep(index)} disabled={steps.length === 1} />
              </div>
            ))}
          </div>
        </section>

        <button
          type="submit"
          disabled={isSubmitting}
          className="flex w-full items-center justify-center gap-2 rounded-full bg-ember px-6 py-3.5 text-sm font-semibold text-cream shadow-md shadow-ember/25 transition-transform hover:scale-[1.01] disabled:cursor-not-allowed disabled:opacity-60"
        >
          {isSubmitting ? 'Publishing...' : 'Publish recipe'}
        </button>
      </form>
    </div>
  )
}

const inputClass =
  'w-full rounded-xl border border-border-subtle/70 bg-surface px-4 py-2.5 text-sm text-cream placeholder:text-muted/70 outline-none focus:border-ember/50 focus:ring-2 focus:ring-ember/20'

const addButtonClass =
  'flex items-center gap-1.5 rounded-full border border-border-subtle/70 px-3 py-1.5 text-xs font-semibold text-cream transition-colors hover:border-ember/40 hover:text-ember-light'

function Field({ label, children }) {
  return (
    <label className="block">
      <span className="mb-1.5 block text-sm font-medium text-cream">{label}</span>
      {children}
    </label>
  )
}

function RemoveButton({ onClick, disabled }) {
  return (
    <button
      type="button"
      onClick={onClick}
      disabled={disabled}
      className="flex h-9 w-9 shrink-0 items-center justify-center rounded-xl border border-border-subtle/70 text-muted transition-colors hover:border-rose-300 hover:text-rose-600 disabled:cursor-not-allowed disabled:opacity-30"
      aria-label="Remove"
    >
      <CloseIcon className="h-4 w-4" />
    </button>
  )
}
