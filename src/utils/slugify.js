/**
 * Converts a string into a URL-friendly slug.
 * Handles Turkish characters and removes special symbols.
 */
function slugify(text) {
  if (!text) return "";
  
  const trMap = {
    'ç': 'c', 'Ç': 'C',
    'ğ': 'g', 'Ğ': 'G',
    'ş': 's', 'Ş': 'S',
    'ü': 'u', 'Ü': 'U',
    'ı': 'i', 'İ': 'I',
    'ö': 'o', 'Ö': 'O'
  };

  for (const [key, value] of Object.entries(trMap)) {
    text = text.replace(new RegExp(key, 'g'), value);
  }

  return text
    .toString()
    .toLowerCase()
    .trim()
    .replace(/\s+/g, '-')     // Replace spaces with -
    .replace(/[^\w-]+/g, '')  // Remove all non-word chars
    .replace(/--+/g, '-')      // Replace multiple - with single -
    .replace(/^-+/, '')       // Trim - from start of text
    .replace(/-+$/, '');      // Trim - from end of text
}

module.exports = { slugify };
