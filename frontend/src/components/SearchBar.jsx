import { SearchIcon } from './icons.jsx'

export default function SearchBar({ value, onChange, placeholder = 'Search recipes, ingredients, cuisines...' }) {
  return (
    <div className="relative w-full">
      <SearchIcon className="pointer-events-none absolute left-4 top-1/2 h-5 w-5 -translate-y-1/2 text-muted" />
      <input
        type="text"
        value={value}
        onChange={(event) => onChange(event.target.value)}
        placeholder={placeholder}
        className="w-full rounded-full border border-border-subtle/70 bg-card py-3.5 pl-12 pr-5 text-sm text-cream placeholder:text-muted/70 outline-none transition-colors focus:border-ember/50 focus:ring-2 focus:ring-ember/20"
      />
    </div>
  )
}
