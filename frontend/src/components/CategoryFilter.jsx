export default function CategoryFilter({ categories, selected, onSelect }) {
  return (
    <div className="flex gap-2 overflow-x-auto pb-1 scrollbar-none">
      {categories.map((category) => (
        <button
          key={category}
          type="button"
          onClick={() => onSelect(category)}
          className={`whitespace-nowrap rounded-full border px-4 py-2 text-sm font-medium transition-all ${
            selected === category
              ? 'border-ember bg-ember text-cream shadow-md shadow-ember/20'
              : 'border-border-subtle/70 bg-card text-muted hover:border-ember/40 hover:text-cream'
          }`}
        >
          {category}
        </button>
      ))}
    </div>
  )
}
