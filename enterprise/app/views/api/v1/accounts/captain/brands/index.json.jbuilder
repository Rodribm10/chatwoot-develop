json.key_format! camelize: :lower
json.array! @brands, partial: 'api/v1/accounts/captain/brands/brand', as: :brand
