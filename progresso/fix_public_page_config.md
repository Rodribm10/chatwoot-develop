# Fix Public Page Configuration

## Objective

Ensure that "General Settings" in the Dashboard (Page Title, Subtitle, Phone, Primary Color) are correctly reflected in the Public Booking Page (`CaptainBooking`).

## Context

The user reported that changing settings in the dashboard had no effect on the public page. The public page was using hardcoded values.

## Steps Taken

1.  **Backend**:

    - Identified that `phone_number` column was missing in `captain_configurations` table.
    - Created migration `AddPhoneNumberToCaptainConfigurations`.
    - Updated `Api::V1::Accounts::Captain::ConfigurationsController` to permit `phone_number` param.
    - Verified `Public::Api::V1::Captain::MasterDataController` returns the `captain_configuration` data.

2.  **Frontend (`App.vue`)**:
    - Updated `fetchMasterData` to consume `app_config` from the API response.
    - Made `appConfig` reactive to the fetched data (`title`, `subtitle`, `phone_number`, `primary_color`, `secondary_color`).
    - Added dynamic background gradient using `primary_color` and `secondary_color`.
    - Added "Suporte: [Phone]" display in the header/subtitle area if a phone number is set.

## Files Changed

- `db/migrate/20260114101014_add_phone_number_to_captain_configurations.rb` (New)
- `enterprise/app/controllers/api/v1/accounts/captain/configurations_controller.rb`
- `app/javascript/captain_booking/App.vue`

## Validation

- Dashboard UI (`configurations/Index.vue`) already supported sending `phone_number`.
- `App.vue` now dynamically updates its UI based on the API response.
