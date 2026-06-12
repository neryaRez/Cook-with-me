import { Link } from 'react-router-dom'
import { ChefHatIcon } from './icons.jsx'

export default function Footer() {
  return (
    <footer className="border-t border-border-subtle/70 bg-surface/60">
      <div className="mx-auto max-w-7xl px-4 py-10 sm:px-6 lg:px-8">
        <div className="flex flex-col items-start justify-between gap-8 md:flex-row">
          <div className="max-w-sm">
            <Link to="/" className="flex items-center gap-2.5 text-cream">
              <span className="flex h-8 w-8 items-center justify-center rounded-lg bg-ember/15 text-ember-light">
                <ChefHatIcon className="h-4 w-4" />
              </span>
              <span className="font-display text-base font-bold">
                Cook <span className="text-gradient">With Me</span>
              </span>
            </Link>
            <p className="mt-3 text-sm leading-relaxed text-muted">
              A community kitchen for home cooks - browse recipes, share your
              own creations, and get real-time help from Robo Chef, your AI
              sous-chef.
            </p>
          </div>

          <div className="grid grid-cols-2 gap-8 sm:gap-16">
            <div>
              <h3 className="font-display text-sm font-semibold text-cream">Explore</h3>
              <ul className="mt-3 space-y-2 text-sm text-muted">
                <li><Link to="/" className="hover:text-ember-light">Home</Link></li>
                <li><Link to="/recipes" className="hover:text-ember-light">Recipes</Link></li>
                <li><Link to="/create" className="hover:text-ember-light">Create Recipe</Link></li>
              </ul>
            </div>
            <div>
              <h3 className="font-display text-sm font-semibold text-cream">Robo Chef</h3>
              <ul className="mt-3 space-y-2 text-sm text-muted">
                <li><Link to="/robo-chef" className="hover:text-ember-light">Ask a question</Link></li>
                <li><Link to="/robo-chef" className="hover:text-ember-light">Cooking tips</Link></li>
                <li><Link to="/robo-chef" className="hover:text-ember-light">Ingredient swaps</Link></li>
              </ul>
            </div>
          </div>
        </div>

        <div className="mt-10 flex flex-col items-center justify-between gap-3 border-t border-border-subtle/60 pt-6 text-xs text-muted sm:flex-row">
          <p>&copy; {new Date().getFullYear()} Cook With Me. All rights reserved.</p>
          <p>Built for the Cook With Me DevOps/AI assignment.</p>
        </div>
      </div>
    </footer>
  )
}
