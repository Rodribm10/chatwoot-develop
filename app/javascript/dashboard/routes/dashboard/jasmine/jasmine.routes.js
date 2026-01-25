import { frontendURL } from '../../../helper/URLHelper';

import JasmineWrapper from './pages/JasmineWrapper.vue';
import JasmineInboxes from './pages/JasmineInboxes.vue';
import JasmineInboxDashboard from './pages/JasmineInboxDashboard.vue';
import JasminePlayground from './pages/JasminePlayground.vue';

const routes = [
  {
    path: frontendURL('accounts/:accountId/jasmine'),
    component: JasmineWrapper,
    children: [
      {
        path: '',
        name: 'jasmine_index',
        redirect: 'inboxes',
      },
      {
        path: 'inboxes',
        name: 'jasmine_inboxes',
        component: JasmineInboxes,
        meta: {
          permissions: ['administrator', 'agent'],
        },
      },
      {
        path: 'inboxes/:inboxId',
        name: 'jasmine_inbox_dashboard',
        component: JasmineInboxDashboard,
        meta: {
          permissions: ['administrator', 'agent'],
        },
      },
      {
        path: 'playground',
        name: 'jasmine_playground',
        component: JasminePlayground,
        meta: {
          permissions: ['administrator', 'agent'],
        },
      },
    ],
  },
];

export default routes;
