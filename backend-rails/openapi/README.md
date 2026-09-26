# API v1 contract

`v1.yaml` is the contract for the frontend application. Each operation declares
`x-implementation-status`:

- `implemented`: the Rails route exists and has request tests.
- `planned`: a draft of a future operation; it is **not** available yet. Its
  payload and authorization details must be finalized with the feature that
  implements it.

The only implemented v1 operation in this foundation is `GET /api/v1/health`.
Unknown paths under `/api/v1` return a JSON `not_found` error. Existing
server-rendered routes remain available during migration to the separate
frontend.

The voting interface is device-independent: a managed phone, computer, or
tablet can host it. Planned API paths use `voting-device` for this role. The
server controls release and confirmation regardless of screen type.

The full RSpec suite includes `spec/contracts/openapi_v1_spec.rb` and the
request checks. CI first migrates an empty PostgreSQL database, then runs the
suite. When an operation is implemented, update its OpenAPI status and add
request tests for its payload, authorization, and errors in the same change.
