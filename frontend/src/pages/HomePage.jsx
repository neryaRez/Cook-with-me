import { useEffect, useState } from 'react'
import { Link } from 'react-router-dom'
import { getRecipes } from '../services/api.js'
import RecipeCard from '../components/RecipeCard.jsx'
import Loader from '../components/Loader.jsx'
import { ChefHatIcon, SparklesIcon } from '../components/icons.jsx'

const stats = [
  { label: 'Community recipes', value: '1,200+' },
  { label: 'Home cooks', value: '8,400+' },
]

export default function HomePage() {
  const [recipes, setRecipes] = useState([])
  const [isLoading, setIsLoading] = useState(true)

  useEffect(() => {
    let isMounted = true
    getRecipes()
      .then((data) => {
        if (isMounted) setRecipes(data)
      })
      .finally(() => {
        if (isMounted) setIsLoading(false)
      })
    return () => {
      isMounted = false
    }
  }, [])

  const featured = [...recipes].sort((a, b) => b.rating - a.rating).slice(0, 3)

  return (
    <div>
      {/* Hero */}
      <section className="relative overflow-hidden bg-noise">
        <div className="absolute inset-0">
          <img
            src="https://images.unsplash.com/photo-1543353071-873f17a7a088?auto=format&fit=crop&w=2000&q=80"
            alt=""
            className="h-full w-full object-cover opacity-40"
          />
          <div className="absolute inset-0 bg-gradient-to-b from-ink/10 via-ink/80 to-ink" />
        </div>

        <div className="relative mx-auto max-w-7xl px-4 py-24 sm:px-6 sm:py-32 lg:px-8">
          <div className="mx-auto max-w-3xl text-center">
            <span className="inline-flex items-center gap-2 rounded-full border border-border-subtle/70 bg-surface/70 px-4 py-1.5 text-sm font-medium text-amber backdrop-blur-sm">
              <SparklesIcon className="h-4 w-4" />
              Now with Robo Chef, your AI sous-chef
            </span>

            <h1 className="mt-6 font-display text-4xl font-extrabold leading-tight tracking-tight text-cream sm:text-5xl lg:text-6xl">
              Cook smarter, share more,
              <br />
              <span className="text-gradient">with a little AI magic.</span>
            </h1>

            <p className="mx-auto mt-6 max-w-xl text-base leading-relaxed text-muted sm:text-lg">
              Discover community recipes, publish your own creations, and ask
              Robo Chef for substitutions, techniques, and ideas - all in one
              place.
            </p>

            <div className="mt-8 flex flex-col items-center justify-center gap-3 sm:flex-row">
              <Link
                to="/recipes"
                className="flex w-full items-center justify-center gap-2 rounded-full bg-ember px-6 py-3.5 text-sm font-semibold text-cream shadow-lg shadow-ember/30 transition-transform hover:scale-[1.03] sm:w-auto"
              >
                Explore Recipes
              </Link>
              <Link
                to="/robo-chef"
                className="flex w-full items-center justify-center gap-2 rounded-full border border-border-subtle/70 bg-surface/70 px-6 py-3.5 text-sm font-semibold text-cream backdrop-blur-sm transition-colors hover:border-ember/40 sm:w-auto"
              >
                <ChefHatIcon className="h-4 w-4 text-ember-light" />
                Ask Robo Chef
              </Link>
            </div>
          </div>

          <div className="mx-auto mt-16 grid max-w-md grid-cols-2 gap-4">
            {stats.map((stat) => (
              <div
                key={stat.label}
                className="rounded-2xl border border-border-subtle/70 bg-surface/60 px-6 py-5 text-center backdrop-blur-sm"
              >
                <p className="font-display text-2xl font-extrabold text-ember-light">{stat.value}</p>
                <p className="mt-1 text-sm text-muted">{stat.label}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Featured recipes */}
      <section className="mx-auto max-w-7xl px-4 py-14 sm:px-6 lg:px-8">
        <div className="flex flex-wrap items-end justify-between gap-4">
          <div>
            <h2 className="font-display text-2xl font-bold text-cream sm:text-3xl">Top-rated recipes</h2>
            <p className="mt-1 text-sm text-muted">Loved by the Cook With Me community.</p>
          </div>
          <Link to="/recipes" className="flex items-center gap-1 text-sm font-semibold text-ember-light hover:underline">
            See more
          </Link>
        </div>

        {isLoading ? (
          <Loader label="Loading featured recipes..." />
        ) : (
          <div className="mt-6 grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-3">
            {featured.map((recipe) => (
              <RecipeCard key={recipe.id} recipe={recipe} />
            ))}
          </div>
        )}
      </section>

    </div>
  )
}
