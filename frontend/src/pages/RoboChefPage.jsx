import ChatInterface from '../components/ChatInterface.jsx'
import { ChefHatIcon, SparklesIcon } from '../components/icons.jsx'

export default function RoboChefPage() {
  return (
    <div className="mx-auto max-w-4xl px-4 py-10 sm:px-6 lg:px-8">
      <div className="text-center">
        <span className="mx-auto flex h-14 w-14 items-center justify-center rounded-2xl bg-ember/15 text-ember-light">
          <ChefHatIcon className="h-7 w-7" />
        </span>
        <h1 className="mt-4 font-display text-3xl font-bold text-cream sm:text-4xl">Robo Chef</h1>
        <p className="mx-auto mt-2 max-w-xl text-sm text-muted">
          Your AI sous-chef. Ask about ingredient swaps, techniques, timings,
          or describe what&apos;s in your fridge for instant recipe ideas.
        </p>
        <span className="mt-3 inline-flex items-center gap-1.5 rounded-full bg-ember/10 px-3 py-1 text-xs font-medium text-ember-light">
          <SparklesIcon className="h-3.5 w-3.5" />
          Responses are simulated for this preview
        </span>
      </div>

      <div className="mt-8 h-[36rem] overflow-hidden rounded-3xl border border-border-subtle/70 bg-card shadow-xl shadow-black/20">
        <ChatInterface />
      </div>
    </div>
  )
}
