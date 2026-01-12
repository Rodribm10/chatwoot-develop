json.account_id resource.account_id
json.config resource.config
json.created_at resource.created_at.to_i
json.description resource.description
json.guardrails resource.guardrails
json.id resource.id
json.name resource.name
json.response_guidelines resource.response_guidelines
json.updated_at resource.updated_at.to_i
json.llm_provider resource.llm_provider
json.llm_model resource.llm_model
json.api_key resource.api_key
json.handoff_webhook_config resource.handoff_webhook_config
default_prompt_config = resource.config.merge('system_prompt' => nil, 'system_prompt_blocks' => nil)
default_blocks = Captain::Llm::SystemPromptsService.assistant_prompt_blocks(
  resource.name,
  resource.config['product_name'],
  default_prompt_config
)
json.system_prompt_blocks_preview default_blocks
json.system_prompt_preview Captain::Llm::SystemPromptsService.assistant_prompt_from_blocks(default_blocks)
