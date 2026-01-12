import { createApp } from 'vue';
import BookingApp from '../captain_booking/App.vue';
import '../captain_booking/assets/main.css';

document.addEventListener('DOMContentLoaded', () => {
  const app = createApp(BookingApp);
  app.mount('#root');
});
