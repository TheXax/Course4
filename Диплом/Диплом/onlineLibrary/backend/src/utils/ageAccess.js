/**
 * Возрастной доступ к книгам по age_rating и birth_date пользователя.
 */

export const AGE_RATINGS = ['0+', '6+', '12+', '16+', '18+'];

export const AGE_RATING_MIN_AGE = {
  '0+': 0,
  '6+': 6,
  '12+': 12,
  '16+': 16,
  '18+': 18
};

export function isAdminRequest(req) {
  return req.user?.role_id === 1 || req.user?.role_name === 'admin';
}

export function getUserAgeFromRequest(req) {
  const birth = req.user?.birth_date;
  if (!birth) return null;
  const bd = new Date(birth);
  if (Number.isNaN(bd.getTime())) return null;
  const today = new Date();
  let age = today.getFullYear() - bd.getFullYear();
  const m = today.getMonth() - bd.getMonth();
  if (m < 0 || (m === 0 && today.getDate() < bd.getDate())) {
    age--;
  }
  return age;
}

/** Гость или нет даты рождения — только 12+. Админ — все рейтинги. */
export function allowedAgeRatingsForRequest(req) {
  if (isAdminRequest(req)) return [...AGE_RATINGS];
  const age = getUserAgeFromRequest(req);
  if (age == null) return ['0+', '6+', '12+', '16+', '18+']; // Если возраст не определен, разрешаем только 0+, 6+, 12+, 16+, 18+
  return AGE_RATINGS.filter((tag) => AGE_RATING_MIN_AGE[tag] <= age);
}

/** null, если в БД устаревшее/некорректное значение (не из списка 0+/6+/12+/16+/18+) */
export function normalizeBookAgeRating(rating) {
  const r = (rating || '0+').trim();
  return AGE_RATINGS.includes(r) ? r : null;
}
