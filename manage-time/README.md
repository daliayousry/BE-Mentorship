# Manage Time Use Case

## Overview

_Describe the goal of the Manage Time use case._

## Actors

- _Who interacts with the system?_

## Requirements

### Functional
- _..._

### Non-Functional
- _..._

| ID | Category | Requirement |
|---|---|---|
| NFR-01 | Security | Every manager action is authorized through the Auth Service using role-based permissions |
| NFR-02 | Consistency | Status change and balance deduction are written in a single DB transaction |
| NFR-03 | Concurrency | A request can be decided only once; deciding a non-`PENDING` request returns `409 Conflict` |
| NFR-04 | Reliability | Notifications are sent asynchronously through events, so an email failure does not fail the request |
| NFR-05 | Usability | Validation errors are returned as `422` with clear messages shown to the user |
| NFR-06 | Performance | Listing pending requests and submitting a request respond in under 500 ms (p95) |
| NFR-07 | Availability | The Vacation Service targets 99.9% uptime |

## Flow

1. _..._

## Diagrams

Diagrams for this use case live in [`diagrams/`](diagrams/).
