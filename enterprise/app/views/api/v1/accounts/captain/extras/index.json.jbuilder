json.key_format! camelize: :lower
json.array! @extras, partial: 'api/v1/accounts/captain/extras/extra', as: :extra
