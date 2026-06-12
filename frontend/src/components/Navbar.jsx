import { NavLink } from 'react-router-dom'
import { ChefHatIcon, PlusIcon, SparklesIcon } from './icons.jsx'

const navLinks = [
  { to: '/', label: 'Home' },
  { to: '/recipes', label: 'Recipes' },
  { to: '/robo-chef', label: 'Robo Chef' },
]

export default function Navbar() {
  return (
    <header className="sticky top-0 z-40 border-b border-border-subtle/70 bg-ink/85 backdrop-blur-md">
      <div className="mx-auto flex max-w-7xl items-center justify-between px-4 py-4 sm:px-6 lg:px-8">
        <NavLink to="/" className="flex items-center gap-2.5 text-cream">
          <span className="flex h-9 w-9 items-center justify-center rounded-xl bg-ember/15 text-ember-light">
            <ChefHatIcon className="h-5 w-5" />
          </span>
          <span className="font-display text-lg font-bold tracking-tight">
            Cook <span className="text-gradient">With Me</span>
          </span>
        </NavLink>

        <nav className="hidden items-center gap-1 rounded-full border border-border-subtle/70 bg-surface/60 p-1 md:flex">
          {navLinks.map((link) => (
            <NavLink
              key={link.to}
              to={link.to}
              end={link.to === '/'}
              className={({ isActive }) =>
                `rounded-full px-4 py-2 text-sm font-medium transition-colors ${
                  isActive
                    ? 'bg-ember text-cream shadow-sm shadow-ember/30'
                    : 'text-muted hover:text-cream'
                }`
              }
            >
              {link.label}
            </NavLink>
          ))}
        </nav>

        <div className="flex items-center gap-2">
          <NavLink
            to="/robo-chef"
            className="hidden items-center gap-1.5 rounded-full border border-border-subtle/70 px-3.5 py-2 text-sm font-medium text-muted transition-colors hover:border-ember/40 hover:text-cream sm:flex md:hidden"
          >
            <SparklesIcon className="h-4 w-4 text-ember-light" />
            Robo Chef
          </NavLink>
          <NavLink
            to="/create"
            className="flex items-center gap-1.5 rounded-full bg-ember px-4 py-2 text-sm font-semibold text-cream shadow-md shadow-ember/25 transition-transform hover:scale-[1.03] active:scale-[0.98]"
          >
            <PlusIcon className="h-4 w-4" />
            <span className="hidden sm:inline">New Recipe</span>
            <span className="sm:hidden">New</span>
          </NavLink>
        </div>
      </div>

      <nav className="flex items-center gap-1 overflow-x-auto border-t border-border-subtle/60 px-4 py-2 md:hidden">
        {navLinks.map((link) => (
          <NavLink
            key={link.to}
            to={link.to}
            end={link.to === '/'}
            className={({ isActive }) =>
              `whitespace-nowrap rounded-full px-3.5 py-1.5 text-sm font-medium transition-colors ${
                isActive ? 'bg-ember text-cream' : 'text-muted hover:text-cream'
              }`
            }
          >
            {link.label}
          </NavLink>
        ))}
      </nav>
    </header>
  )
}
