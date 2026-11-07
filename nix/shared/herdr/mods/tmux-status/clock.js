const DAYS = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
const MONTHS = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
const pad = value => String(value).padStart(2, "0");

export function formatStatusTime(date) {
  const time = `${pad(date.getHours())}:${pad(date.getMinutes())}`;
  const day = `${DAYS[date.getDay()]} ${pad(date.getDate())}-${MONTHS[date.getMonth()]}-${pad(date.getFullYear() % 100)}`;
  return `${time} ${day}`;
}
