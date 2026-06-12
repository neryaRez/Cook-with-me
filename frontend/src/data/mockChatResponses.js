// Canned Robo Chef responses, keyed by topic keywords found in the user's message.
// askRoboChef() in src/services/api.js picks a response based on these keywords,
// falling back to a friendly default when nothing matches.
export const chatKeywordResponses = [
  {
    keywords: ['substitute', 'replace', 'instead of', 'swap'],
    reply:
      "Good question! For most baking recipes you can swap butter for an equal amount of neutral oil, or use Greek yogurt for a lighter texture. If it's an egg you're replacing, a tablespoon of flaxseed mixed with water works great as a binder.",
  },
  {
    keywords: ['vegan', 'vegetarian', 'plant'],
    reply:
      'Easy! Swap dairy for plant-based alternatives like oat milk or cashew cream, and replace meat with chickpeas, lentils, tofu, or jackfruit depending on the texture you want. I can suggest a full vegan version of any recipe if you tell me which one.',
  },
  {
    keywords: ['time', 'how long', 'minutes', 'quick'],
    reply:
      'Most weeknight-friendly recipes on Cook With Me are designed to be ready in 30 minutes or less. If you are short on time, look for the "Easy" difficulty tag - those usually have minimal prep and one-pan cleanup.',
  },
  {
    keywords: ['spicy', 'spice', 'heat', 'chili'],
    reply:
      'To turn up the heat, add fresh chili, a spoonful of chili crisp, or a pinch of cayenne. Start small - you can always add more, but it is hard to tone spice back down once it is in!',
  },
  {
    keywords: ['pasta', 'spaghetti', 'noodle'],
    reply:
      'For perfect pasta, salt your boiling water generously (it should taste like the sea) and always save a cup of starchy pasta water - it helps bind sauces beautifully, especially creamy ones.',
  },
  {
    keywords: ['bake', 'baking', 'oven', 'cake', 'cheesecake'],
    reply:
      'Baking is all about precision! Make sure your oven is fully preheated, measure dry ingredients by weight if you can, and avoid opening the oven door too early - it can cause cakes and cheesecakes to sink.',
  },
  {
    keywords: ['store', 'leftover', 'fridge', 'freeze'],
    reply:
      'Most cooked dishes keep well in an airtight container in the fridge for 3-4 days. For longer storage, portion and freeze - soups, stews, and sauces freeze especially well for up to 3 months.',
  },
  {
    keywords: ['hello', 'hi', 'hey'],
    reply:
      "Hey there! I'm Robo Chef, your AI sous-chef. Ask me about ingredient swaps, cooking techniques, or tell me what's in your fridge and I'll suggest something to make.",
  },
]

export const defaultChatReply =
  "That's a great cooking question! While my full knowledge base is still being connected, here's a tip: taste as you go and adjust seasoning gradually - it's the single biggest upgrade for any home-cooked meal."
