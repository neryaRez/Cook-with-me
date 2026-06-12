import { useState } from 'react'
import { useLocation } from 'react-router-dom'
import ChatInterface from './ChatInterface.jsx'
import { ChefHatIcon, CloseIcon, SparklesIcon } from './icons.jsx'

export default function RoboChefWidget() {
  const [isOpen, setIsOpen] = useState(false)
  const location = useLocation()

  // The dedicated Robo Chef page already offers the full chat experience.
  if (location.pathname === '/robo-chef') {
    return null
  }

  return (
    <>
      {isOpen && (
        <div className="fixed bottom-24 right-4 z-50 flex h-[28rem] w-[22rem] max-w-[calc(100vw-2rem)] flex-col overflow-hidden rounded-2xl border border-border-subtle/70 bg-card shadow-2xl shadow-black/50 sm:right-6">
          <div className="flex items-center justify-between border-b border-border-subtle/70 bg-surface px-4 py-3">
            <div className="flex items-center gap-2">
              <span className="flex h-8 w-8 items-center justify-center rounded-full bg-ember/15 text-ember-light">
                <ChefHatIcon className="h-4 w-4" />
              </span>
              <div>
                <p className="font-display text-sm font-semibold text-cream">Robo Chef</p>
                <p className="text-xs text-muted">Your AI sous-chef</p>
              </div>
            </div>
            <button
              type="button"
              onClick={() => setIsOpen(false)}
              className="flex h-8 w-8 items-center justify-center rounded-full text-muted transition-colors hover:bg-card-hover hover:text-cream"
              aria-label="Close Robo Chef"
            >
              <CloseIcon className="h-4 w-4" />
            </button>
          </div>
          <div className="flex-1 overflow-hidden">
            <ChatInterface compact />
          </div>
        </div>
      )}

      <button
        type="button"
        onClick={() => setIsOpen((prev) => !prev)}
        className="fixed bottom-6 right-4 z-50 flex items-center gap-2 rounded-full bg-ember px-5 py-3.5 font-semibold text-cream shadow-xl shadow-ember/30 transition-transform hover:scale-105 active:scale-95 sm:right-6"
        aria-label="Toggle Robo Chef chat"
      >
        {isOpen ? <CloseIcon className="h-5 w-5" /> : <SparklesIcon className="h-5 w-5" />}
        <span className="hidden sm:inline">{isOpen ? 'Close' : 'Robo Chef'}</span>
      </button>
    </>
  )
}
