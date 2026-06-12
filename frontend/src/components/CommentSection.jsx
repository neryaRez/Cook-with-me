import { useState } from 'react'
import { createComment } from '../services/api.js'
import { SendIcon } from './icons.jsx'

export default function CommentSection({ recipeId, comments, onCommentAdded }) {
  const [text, setText] = useState('')
  const [isSubmitting, setIsSubmitting] = useState(false)

  async function handleSubmit(event) {
    event.preventDefault()
    const trimmed = text.trim()
    if (!trimmed || isSubmitting) return

    setIsSubmitting(true)
    try {
      const newComment = await createComment(recipeId, { author: 'You', text: trimmed })
      onCommentAdded(newComment)
      setText('')
    } finally {
      setIsSubmitting(false)
    }
  }

  return (
    <div className="space-y-5">
      <h2 className="font-display text-xl font-bold text-cream">
        Comments <span className="text-muted">({comments.length})</span>
      </h2>

      <form onSubmit={handleSubmit} className="flex items-start gap-3">
        <span className="mt-1 flex h-9 w-9 shrink-0 items-center justify-center rounded-full bg-ember/15 text-sm font-semibold text-ember-light">
          Y
        </span>
        <div className="flex-1">
          <textarea
            value={text}
            onChange={(event) => setText(event.target.value)}
            placeholder="Share a tip, a tweak, or how it turned out..."
            rows={2}
            className="w-full resize-none rounded-2xl border border-border-subtle/70 bg-surface px-4 py-3 text-sm text-cream placeholder:text-muted/70 outline-none focus:border-ember/50 focus:ring-2 focus:ring-ember/20"
          />
          <div className="mt-2 flex justify-end">
            <button
              type="submit"
              disabled={isSubmitting || !text.trim()}
              className="flex items-center gap-2 rounded-full bg-ember px-4 py-2 text-sm font-semibold text-cream transition-transform hover:scale-[1.02] disabled:cursor-not-allowed disabled:opacity-40"
            >
              <SendIcon className="h-4 w-4" />
              {isSubmitting ? 'Posting...' : 'Post comment'}
            </button>
          </div>
        </div>
      </form>

      <div className="space-y-4">
        {comments.length === 0 && (
          <p className="text-sm text-muted">No comments yet - be the first to share your thoughts.</p>
        )}
        {comments
          .slice()
          .reverse()
          .map((comment) => (
            <div key={comment.id} className="flex items-start gap-3">
              <span className="mt-1 flex h-9 w-9 shrink-0 items-center justify-center rounded-full bg-surface text-sm font-semibold text-cream">
                {comment.author.charAt(0).toUpperCase()}
              </span>
              <div className="flex-1 rounded-2xl border border-border-subtle/70 bg-surface px-4 py-3">
                <div className="flex items-center justify-between gap-3">
                  <p className="text-sm font-semibold text-cream">{comment.author}</p>
                  <p className="text-xs text-muted">{comment.date}</p>
                </div>
                <p className="mt-1 text-sm leading-relaxed text-muted">{comment.text}</p>
              </div>
            </div>
          ))}
      </div>
    </div>
  )
}
