import { FEATURE_FLAGS } from 'dashboard/featureFlags';
import { INSTALLATION_TYPES } from 'dashboard/constants/installationTypes';
import { frontendURL } from '../../../helper/URLHelper';

import CaptainPageRouteView from './pages/CaptainPageRouteView.vue';
import AssistantsIndexPage from './pages/AssistantsIndexPage.vue';
import AssistantEmptyStateIndex from './assistants/Index.vue';
import CaptainToolsPage from './pages/CaptainToolsPage.vue';
import AssetsIndex from './assets/Index.vue';
import ReservationsIndex from './reservations/Index.vue';
import UnitsIndex from './units/Index.vue';
import BrandsIndex from './brands/Index.vue';
import PricingsIndex from './pricings/Index.vue';
import ExtrasIndex from './extras/Index.vue';
import RemindersIndex from './reminders/Index.vue';
import ConfigurationsIndex from './configurations/Index.vue';

// Missing imports restored
import ResponsesIndex from './responses/Index.vue';
import ResponsesPendingIndex from './responses/Pending.vue';
import DocumentsIndex from './documents/Index.vue';
import AssistantToolsIndex from './assistants/tools/Index.vue';
import AssistantScenariosIndex from './assistants/scenarios/Index.vue';
import AssistantPlaygroundIndex from './assistants/playground/Index.vue';
import AssistantInboxesIndex from './assistants/inboxes/Index.vue';
import AssistantSettingsIndex from './assistants/settings/Settings.vue';
import AssistantGuardrailsIndex from './assistants/guardrails/Index.vue';
import AssistantGuidelinesIndex from './assistants/guidelines/Index.vue';

const meta = {
  permissions: ['administrator', 'agent'],
  featureFlag: FEATURE_FLAGS.CAPTAIN,
  installationTypes: [INSTALLATION_TYPES.CLOUD, INSTALLATION_TYPES.ENTERPRISE],
};

const metaV2 = {
  permissions: ['administrator', 'agent'],
  featureFlag: FEATURE_FLAGS.CAPTAIN,
  installationTypes: [INSTALLATION_TYPES.CLOUD, INSTALLATION_TYPES.ENTERPRISE],
};

const globalRoutes = [
  {
    path: frontendURL('accounts/:accountId/captain/tools'),
    component: CaptainToolsPage,
    name: 'captain_global_tools_index',
    meta,
  },
  {
    path: frontendURL('accounts/:accountId/captain/assets'),
    component: AssetsIndex,
    name: 'captain_assets_index',
    meta,
  },
  {
    path: frontendURL('accounts/:accountId/captain/reservations'),
    component: ReservationsIndex,
    name: 'captain_reservations_index',
    meta,
  },
  {
    path: frontendURL('accounts/:accountId/captain/units'),
    component: UnitsIndex,
    name: 'captain_units_index',
    meta: {
      permissions: ['administrator'],
      featureFlag: FEATURE_FLAGS.CAPTAIN,
      installationTypes: [
        INSTALLATION_TYPES.CLOUD,
        INSTALLATION_TYPES.ENTERPRISE,
      ],
    },
  },
  {
    path: frontendURL('accounts/:accountId/captain/brands'),
    component: BrandsIndex,
    name: 'captain_brands_index',
    meta: {
      permissions: ['administrator'],
      featureFlag: FEATURE_FLAGS.CAPTAIN,
      installationTypes: [
        INSTALLATION_TYPES.CLOUD,
        INSTALLATION_TYPES.ENTERPRISE,
      ],
    },
  },
  {
    path: frontendURL('accounts/:accountId/captain/pricings'),
    component: PricingsIndex,
    name: 'captain_pricings_index',
    meta: {
      permissions: ['administrator'],
      featureFlag: FEATURE_FLAGS.CAPTAIN,
      installationTypes: [
        INSTALLATION_TYPES.CLOUD,
        INSTALLATION_TYPES.ENTERPRISE,
      ],
    },
  },
  {
    path: frontendURL('accounts/:accountId/captain/extras'),
    component: ExtrasIndex,
    name: 'captain_extras_index',
    meta: {
      permissions: ['administrator'],
      featureFlag: FEATURE_FLAGS.CAPTAIN,
      installationTypes: [
        INSTALLATION_TYPES.CLOUD,
        INSTALLATION_TYPES.ENTERPRISE,
      ],
    },
  },
  {
    path: frontendURL('accounts/:accountId/captain/reminders'),
    component: RemindersIndex,
    name: 'captain_reminders_index',
    meta: {
      permissions: ['administrator'],
      featureFlag: FEATURE_FLAGS.CAPTAIN,
      installationTypes: [
        INSTALLATION_TYPES.CLOUD,
        INSTALLATION_TYPES.ENTERPRISE,
      ],
    },
  },
  {
    path: frontendURL('accounts/:accountId/captain/configuration'),
    component: ConfigurationsIndex,
    name: 'captain_configurations_index',
    meta: {
      permissions: ['administrator'],
      featureFlag: FEATURE_FLAGS.CAPTAIN,
      installationTypes: [
        INSTALLATION_TYPES.CLOUD,
        INSTALLATION_TYPES.ENTERPRISE,
      ],
    },
  },
];

const assistantRoutes = [
  {
    path: frontendURL('accounts/:accountId/captain/:assistantId/faqs'),
    component: ResponsesIndex,
    name: 'captain_assistants_responses_index',
    meta,
  },
  {
    path: frontendURL('accounts/:accountId/captain/:assistantId/documents'),
    component: DocumentsIndex,
    name: 'captain_assistants_documents_index',
    meta,
  },
  {
    path: frontendURL('accounts/:accountId/captain/:assistantId/tools'),
    component: AssistantToolsIndex,
    name: 'captain_tools_index',
    meta: metaV2,
  },
  {
    path: frontendURL('accounts/:accountId/captain/:assistantId/scenarios'),
    component: AssistantScenariosIndex,
    name: 'captain_assistants_scenarios_index',
    meta: metaV2,
  },
  {
    path: frontendURL('accounts/:accountId/captain/:assistantId/playground'),
    component: AssistantPlaygroundIndex,
    name: 'captain_assistants_playground_index',
    meta,
  },
  {
    path: frontendURL('accounts/:accountId/captain/:assistantId/inboxes'),
    component: AssistantInboxesIndex,
    name: 'captain_assistants_inboxes_index',
    meta,
  },
  {
    path: frontendURL('accounts/:accountId/captain/:assistantId/faqs/pending'),
    component: ResponsesPendingIndex,
    name: 'captain_assistants_responses_pending',
    meta,
  },
  {
    path: frontendURL('accounts/:accountId/captain/:assistantId/settings'),
    component: AssistantSettingsIndex,
    name: 'captain_assistants_settings_index',
    meta,
  },
  // Settings sub-pages (guardrails and guidelines)
  {
    path: frontendURL(
      'accounts/:accountId/captain/:assistantId/settings/guardrails'
    ),
    component: AssistantGuardrailsIndex,
    name: 'captain_assistants_guardrails_index',
    meta: metaV2,
  },
  {
    path: frontendURL(
      'accounts/:accountId/captain/:assistantId/settings/guidelines'
    ),
    component: AssistantGuidelinesIndex,
    name: 'captain_assistants_guidelines_index',
    meta: metaV2,
  },
  {
    path: frontendURL('accounts/:accountId/captain/assistants'),
    component: AssistantEmptyStateIndex,
    name: 'captain_assistants_create_index',
    meta: {
      permissions: ['administrator', 'agent'],
      installationTypes: [
        INSTALLATION_TYPES.CLOUD,
        INSTALLATION_TYPES.ENTERPRISE,
      ],
    },
  },
  {
    path: frontendURL('accounts/:accountId/captain/:navigationPath'),
    component: AssistantsIndexPage,
    name: 'captain_assistants_index',
    meta,
  },
];

export const routes = [
  {
    path: frontendURL('accounts/:accountId/captain'),
    component: CaptainPageRouteView,
    redirect: to => {
      return {
        name: 'captain_assistants_index',
        params: {
          navigationPath: 'captain_assistants_responses_index',
          ...to.params,
        },
      };
    },
    children: [...globalRoutes, ...assistantRoutes],
  },
];
