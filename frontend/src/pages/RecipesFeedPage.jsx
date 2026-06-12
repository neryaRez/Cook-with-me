import { useEffect, useMemo, useState } from 'react'
import { useSearchParams } from 'react-router-dom'
import { getRecipes } from '../services/api.js'
import RecipeCard from '../components/RecipeCard.jsx'
import SearchBar from '../components/SearchBar.jsx'
import CategoryFilter from '../components/CategoryFilter.jsx'
import Loader from '../components/Loader.jsx'
import { categories } from '../data/categories.js'

export default function RecipesFeedPage() {
  const [recipes, setRecipes] = useState([])
  const [isLoading, setIsLoading] = useState(true)
  const [error, setError] = useState(null)
  const [search, setSearch] = useState('')
  const [searchParams, setSearchParams] = useSearchParams()

  const selectedCategory = searchParams.get('category') ?? 'All'

  useEffect(() => {
    let isMounted = true
    setIsLoading(true)
    getRecipes()
      .then((data) => {
        if (isMounted) setRecipes(data)
      })
      .catch(() => {
        if (isMounted) setError('Could not load recipes right now. Please try again later.')
      })
      .finally(() => {
        if (isMounted) setIsLoading(false)
      })
    return () => {
      isMounted = false
    }
  }, [])

  function handleCategorySelect(category) {
    if (category === 'All') {
      setSearchParams({})
    } else {
      setSearchParams({ category })
    }
  }

  const filteredRecipes = useMemo(() => {
    const query = search.trim().toLowerCase()

    return recipes.filter((recipe) => {
      const matchesCategory = selectedCategory === 'All' || recipe.category === selectedCategory
      const matchesQuery =
        !query ||
        recipe.title.toLowerCase().includes(query) ||
        recipe.description.toLowerCase().includes(query) ||
        recipe.cuisine.toLowerCase().includes(query) ||
        recipe.tags.some((tag) => tag.toLowerCase().includes(query))

      return matchesCategory && matchesQuery
    })
  }, [recipes, search, selectedCategory])

  return (
    <div className="mx-auto max-w-7xl px-4 py-10 sm:px-6 lg:px-8">
      <div className="max-w-2xl">
        <h1 className="font-display text-3xl font-bold text-cream sm:text-4xl">Recipe Feed</h1>
        <p className="mt-2 text-sm text-muted">
          Browse recipes shared by the Cook With Me community. Search by name,
          ingredient, or cuisine, or filter by category.
        </p>
      </div>

      <div className="mt-6 space-y-4">
        <SearchBar value={search} onChange={setSearch} />
        <CategoryFilter categories={categories} selected={selectedCategory} onSelect={handleCategorySelect} />
      </div>

      <div className="mt-8">
        {isLoading && <Loader label="Loading recipes..." />}

        {!isLoading && error && (
          <p className="rounded-2xl border border-rose-200 bg-rose-50 px-4 py-3 text-sm text-rose-700">{error}</p>
        )}

        {!isLoading && !error && filteredRecipes.length === 0 && (
          <div className="rounded-2xl border border-border-subtle/70 bg-card px-6 py-12 text-center">
            <p className="font-display text-lg font-semibold text-cream">No recipes found</p>
            <p className="mt-1 text-sm text-muted">Try a different search term or category.</p>
          </div>
        )}

        {!isLoading && !error && filteredRecipes.length > 0 && (
          <>
            <p className="mb-4 text-sm text-muted">
              Showing {filteredRecipes.length} {filteredRecipes.length === 1 ? 'recipe' : 'recipes'}
            </p>
            <div className="grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-3">
              {filteredRecipes.map((recipe) => (
                <RecipeCard key={recipe.id} recipe={recipe} />
              ))}
            </div>
          </>
        )}
      </div>
    </div>
  )
}
