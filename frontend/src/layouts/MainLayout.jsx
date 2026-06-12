import Navbar from '../components/Navbar.jsx'
import Footer from '../components/Footer.jsx'
import RoboChefWidget from '../components/RoboChefWidget.jsx'

export default function MainLayout({ children }) {
  return (
    <div className="flex min-h-screen flex-col bg-ink text-cream">
      <Navbar />
      <main className="flex-1">{children}</main>
      <Footer />
      <RoboChefWidget />
    </div>
  )
}
