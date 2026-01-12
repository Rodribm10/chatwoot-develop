json.key_format! camelize: :lower
json.array! @pricings, partial: 'api/v1/accounts/captain/pricings/pricing', as: :pricing
