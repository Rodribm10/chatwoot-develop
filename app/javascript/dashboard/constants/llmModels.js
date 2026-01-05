export const LLM_MODELS = {
  openai: [
    { value: 'gpt-4o', label: 'GPT-4o (Mais Inteligente)' },
    { value: 'gpt-4o-mini', label: 'GPT-4o Mini (Rapido)' },
    { value: 'gpt-4.1', label: 'GPT-4.1 (Estavel)' },
    { value: 'gpt-4.1-mini', label: 'GPT-4.1 Mini (Barato)' },
    { value: 'o1', label: 'O1 (Raciocinio)' },
    { value: 'o1-mini', label: 'O1 Mini (Raciocinio/Economico)' },
    { value: 'o3-mini', label: 'O3 Mini (Rapido)' },
    { value: 'gpt-3.5-turbo', label: 'GPT-3.5 Turbo (Legado)' },
  ],
  gemini: [
    { value: 'gemini-2.5-pro', label: 'Gemini 2.5 Pro (Mais Potente)' },
    { value: 'gemini-2.5-flash', label: 'Gemini 2.5 Flash (Rapido)' },
    {
      value: 'gemini-2.5-flash-lite',
      label: 'Gemini 2.5 Flash-Lite (Economico)',
    },
    { value: 'gemini-2.0-flash', label: 'Gemini 2.0 Flash' },
    { value: 'gemini-2.0-flash-lite', label: 'Gemini 2.0 Flash-Lite' },
    { value: 'gemini-flash-latest', label: 'Gemini Flash Latest' },
    { value: 'gemini-flash-lite-latest', label: 'Gemini Flash-Lite Latest' },
    { value: 'gemini-pro-latest', label: 'Gemini Pro Latest' },
    { value: 'gemini-3-pro-preview', label: 'Gemini 3 Pro Preview' },
    { value: 'gemini-3-flash-preview', label: 'Gemini 3 Flash Preview' },
  ],
};

export const LLM_PROVIDERS = [
  { value: 'openai', label: 'OpenAI' },
  { value: 'gemini', label: 'Google Gemini' },
];
