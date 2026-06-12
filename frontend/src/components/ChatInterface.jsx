import { useState, useRef, useEffect } from 'react'
import { askRoboChef } from '../services/api.js'
import { SendIcon, SparklesIcon, ChefHatIcon } from './icons.jsx'

const STARTER_PROMPTS = [
  'What can I substitute for eggs?',
  'Give me a quick vegan dinner idea',
  'How do I store leftover pasta?',
  'How can I make this dish spicier?',
]

const INITIAL_MESSAGE = {
  id: 'welcome',
  role: 'assistant',
  text: "Hi, I'm Robo Chef! Ask me about ingredient swaps, techniques, storage tips, or what to cook with what you have on hand.",
}

export default function ChatInterface({ compact = false }) {
  const [messages, setMessages] = useState([INITIAL_MESSAGE])
  const [input, setInput] = useState('')
  const [isThinking, setIsThinking] = useState(false)
  const scrollRef = useRef(null)

  useEffect(() => {
    if (scrollRef.current) {
      scrollRef.current.scrollTop = scrollRef.current.scrollHeight
    }
  }, [messages, isThinking])

  async function sendMessage(text) {
    const trimmed = text.trim()
    if (!trimmed || isThinking) return

    const userMessage = { id: `u-${messages.length}`, role: 'user', text: trimmed }
    setMessages((prev) => [...prev, userMessage])
    setInput('')
    setIsThinking(true)

    try {
      const { reply } = await askRoboChef({ message: trimmed })
      setMessages((prev) => [...prev, { id: `a-${prev.length}`, role: 'assistant', text: reply }])
    } catch {
      setMessages((prev) => [
        ...prev,
        {
          id: `a-${prev.length}`,
          role: 'assistant',
          text: "Sorry, I'm having trouble responding right now. Please try again in a moment.",
        },
      ])
    } finally {
      setIsThinking(false)
    }
  }

  function handleSubmit(event) {
    event.preventDefault()
    sendMessage(input)
  }

  return (
    <div className="flex h-full flex-col">
      <div
        ref={scrollRef}
        className={`flex-1 space-y-4 overflow-y-auto ${compact ? 'p-4' : 'p-6'}`}
      >
        {messages.map((message) => (
          <div
            key={message.id}
            className={`flex items-start gap-2.5 ${message.role === 'user' ? 'justify-end' : 'justify-start'}`}
          >
            {message.role === 'assistant' && (
              <span className="mt-0.5 flex h-7 w-7 shrink-0 items-center justify-center rounded-full bg-ember/15 text-ember-light">
                <ChefHatIcon className="h-4 w-4" />
              </span>
            )}
            <div
              className={`max-w-[80%] rounded-2xl px-4 py-2.5 text-sm leading-relaxed ${
                message.role === 'user'
                  ? 'bg-ember text-cream'
                  : 'border border-border-subtle/70 bg-surface text-cream'
              }`}
            >
              {message.text}
            </div>
          </div>
        ))}

        {isThinking && (
          <div className="flex items-start gap-2.5">
            <span className="mt-0.5 flex h-7 w-7 shrink-0 items-center justify-center rounded-full bg-ember/15 text-ember-light">
              <ChefHatIcon className="h-4 w-4" />
            </span>
            <div className="flex items-center gap-1 rounded-2xl border border-border-subtle/70 bg-surface px-4 py-3">
              <span className="h-1.5 w-1.5 animate-bounce rounded-full bg-muted [animation-delay:-0.3s]" />
              <span className="h-1.5 w-1.5 animate-bounce rounded-full bg-muted [animation-delay:-0.15s]" />
              <span className="h-1.5 w-1.5 animate-bounce rounded-full bg-muted" />
            </div>
          </div>
        )}

        {messages.length === 1 && !isThinking && (
          <div className="grid gap-2 pt-2 sm:grid-cols-2">
            {STARTER_PROMPTS.map((prompt) => (
              <button
                key={prompt}
                type="button"
                onClick={() => sendMessage(prompt)}
                className="flex items-center gap-2 rounded-xl border border-border-subtle/70 bg-surface px-3 py-2.5 text-left text-xs text-muted transition-colors hover:border-ember/40 hover:text-cream"
              >
                <SparklesIcon className="h-3.5 w-3.5 shrink-0 text-ember-light" />
                {prompt}
              </button>
            ))}
          </div>
        )}
      </div>

      <form onSubmit={handleSubmit} className="flex items-center gap-2 border-t border-border-subtle/70 p-3">
        <input
          type="text"
          value={input}
          onChange={(event) => setInput(event.target.value)}
          placeholder="Ask Robo Chef anything about cooking..."
          className="flex-1 rounded-full border border-border-subtle/70 bg-surface px-4 py-2.5 text-sm text-cream placeholder:text-muted/70 outline-none focus:border-ember/50 focus:ring-2 focus:ring-ember/20"
        />
        <button
          type="submit"
          disabled={isThinking || !input.trim()}
          className="flex h-10 w-10 shrink-0 items-center justify-center rounded-full bg-ember text-cream transition-transform hover:scale-105 disabled:cursor-not-allowed disabled:opacity-40"
        >
          <SendIcon className="h-4 w-4" />
        </button>
      </form>
    </div>
  )
}
