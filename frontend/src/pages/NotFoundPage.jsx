import { Link } from 'react-router-dom'
import { ChefHatIcon, ArrowLeftIcon } from '../components/icons.jsx'

export default function NotFoundPage() {
  return (
    <div className="mx-auto flex max-w-2xl flex-col items-center px-4 py-24 text-center">
      <span className="flex h-16 w-16 items-center justify-center rounded-2xl bg-ember/15 text-ember-light">
        <ChefHatIcon className="h-8 w-8" />
      </span>
      <h1 className="mt-6 font-display text-4xl font-extrabold text-cream">404</h1>
      <p className="mt-2 text-lg font-semibold text-cream">This page isn&apos;t on the menu.</p>
      <p className="mt-2 text-sm text-muted">
        The page you&apos;re looking for doesn&apos;t exist or may have been moved.
      </p>
      <Link
        to="/"
        className="mt-8 flex items-center gap-2 rounded-full bg-ember px-5 py-2.5 text-sm font-semibold text-cream"
      >
        <ArrowLeftIcon className="h-4 w-4" />
        Back to home
      </Link>
    </div>
  )
}
