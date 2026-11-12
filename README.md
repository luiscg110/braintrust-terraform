# Braintrust Azure Terraform

This repository is a sanitized snapshot of Braintrust-related Terraform templates. Sensitive values in examples are replaced with `000`. The templates are intentionally non-deployable until approved environment values are supplied outside Git.

## Included

- DEV, UAT, and PROD Terraform roots, lock files, and example inputs.
- The custom DEV private ingress root for AKS Gateway API, an internal load balancer, and DNS.
- Supporting ingress examples and a clearly marked archive of the earlier Application Gateway approach.
- The available DEV mock test.

## Excluded

- Real tfvars, backend configuration, state, identity exports, permission plans, and evidence files.
- `.terraform` provider/module caches.
- The locally adapted Braintrust data-plane module. Its upstream repository does not declare a public redistribution license; obtain the module directly from Braintrust under its applicable terms before using the environment roots.

The environment roots reference `modules/data-plane`, which is intentionally not included. This repository is therefore not a standalone deployment package until that module is obtained and installed under its applicable terms. The DEV ingress root is independent and has a separate example input file.

## Safety

Do not run a plan or apply with placeholder values. Before deployment, supply approved environment values through an untracked tfvars file and external backend configuration, confirm resource ownership, and review the plan. This repository contains no state, credentials, private keys, or actual account identifiers.
