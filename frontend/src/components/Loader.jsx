export default function Loader({ label = 'Loading...' }) {
  return (
    <div className="flex flex-col items-center justify-center gap-3 py-20 text-muted">
      <span className="h-10 w-10 animate-spin rounded-full border-2 border-border-subtle border-t-ember" />
      <p className="text-sm">{label}</p>
    </div>
  )
}
