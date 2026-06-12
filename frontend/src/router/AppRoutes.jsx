import { Routes, Route } from 'react-router-dom'
import HomePage from '../pages/HomePage.jsx'
import RecipesFeedPage from '../pages/RecipesFeedPage.jsx'
import RecipeDetailsPage from '../pages/RecipeDetailsPage.jsx'
import CreateRecipePage from '../pages/CreateRecipePage.jsx'
import RoboChefPage from '../pages/RoboChefPage.jsx'
import NotFoundPage from '../pages/NotFoundPage.jsx'

export default function AppRoutes() {
  return (
    <Routes>
      <Route path="/" element={<HomePage />} />
      <Route path="/recipes" element={<RecipesFeedPage />} />
      <Route path="/recipes/:id" element={<RecipeDetailsPage />} />
      <Route path="/create" element={<CreateRecipePage />} />
      <Route path="/robo-chef" element={<RoboChefPage />} />
      <Route path="*" element={<NotFoundPage />} />
    </Routes>
  )
}
