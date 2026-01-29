# TestBaqio

Application Rails de gestion de commandes et de facturation.

## Ruby version

- Ruby 4.0.1
- Rails 8.1.2

## Dependances systeme

- SQLite 3.8.0+
- Node.js (pour les assets)

## Configuration

1. Cloner le repository
2. Installer les dependances :

```bash
bundle install
```

## Creation de la base de donnees

```bash
bin/rails db:create
bin/rails db:migrate
bin/rails db:seed
```

## Lancer le serveur

```bash
bin/rails server
```

L'application sera accessible sur http://localhost:3000

## Comment lancer les tests

### RSpec

```bash
# Lancer tous les tests RSpec
bundle exec rspec

# Lancer un fichier specifique
bundle exec rspec spec/models/order_spec.rb

# Lancer un test specifique (ligne)
bundle exec rspec spec/models/order_spec.rb:42

# Lancer par type de test
bundle exec rspec spec/models/          # Tests des modeles
bundle exec rspec spec/requests/        # Tests des requetes HTTP
bundle exec rspec spec/decorators/      # Tests des decorateurs
bundle exec rspec spec/services/        # Tests des services
bundle exec rspec spec/queries/         # Tests des queries
bundle exec rspec spec/value_objects/   # Tests des value objects
bundle exec rspec spec/integration/     # Tests d'integration

# Lancer uniquement les tests echoues precedemment
bundle exec rspec --only-failures

# Lancer avec format documentation
bundle exec rspec --format documentation

# Lancer avec seed specifique (reproductibilite)
bundle exec rspec --seed 1234
```

**Structure des tests RSpec :**
- `spec/models/` - Tests unitaires des modeles ActiveRecord
- `spec/models/concerns/` - Tests des concerns (Statusable, Trackable)
- `spec/requests/` - Tests des controllers (requetes HTTP)
- `spec/decorators/` - Tests des decorateurs Draper
- `spec/services/` - Tests des objets service
- `spec/queries/` - Tests des objets query
- `spec/value_objects/` - Tests des value objects
- `spec/integration/` - Tests d'integration complets
- `spec/factories/` - Factories FactoryBot

### Cucumber (BDD)

```bash
# Lancer tous les scenarios Cucumber
bundle exec cucumber

# Lancer un fichier feature specifique
bundle exec cucumber features/orders/workflow.feature

# Lancer un scenario specifique (ligne)
bundle exec cucumber features/orders/workflow.feature:15

# Lancer par tag
bundle exec cucumber --tags @orders
bundle exec cucumber --tags @wip          # Work in progress
bundle exec cucumber --tags "not @slow"   # Exclure les tests lents

# Lancer par dossier
bundle exec cucumber features/orders/       # Features des commandes
bundle exec cucumber features/invoices/     # Features des factures
bundle exec cucumber features/customers/    # Features des clients
bundle exec cucumber features/fulfillments/ # Features des expeditions
bundle exec cucumber features/queries/      # Features des queries
bundle exec cucumber features/integration/  # Features d'integration

# Format de sortie
bundle exec cucumber --format pretty       # Format lisible
bundle exec cucumber --format progress     # Format compact
bundle exec cucumber --format html > report.html  # Rapport HTML
```

**Structure des features Cucumber :**
- `features/accounts/` - Gestion des comptes
- `features/customers/` - Gestion des clients
- `features/orders/` - Workflow des commandes
- `features/invoices/` - Cycle de vie des factures
- `features/fulfillments/` - Expedition et suivi
- `features/events/` - Audit trail et tracking
- `features/queries/` - Queries metier
- `features/services/` - Services de base
- `features/integration/` - Workflow complet

### Lancer tous les tests

```bash
# Tests RSpec + Cucumber
bundle exec rspec && bundle exec cucumber
```

### Analyse de securite

```bash
bundle exec brakeman
bundle exec bundler-audit check
```

### Linting

```bash
bundle exec rubocop
```

## Structure du projet

### Modeles principaux

- `Account` - Comptes utilisateurs
- `Customer` - Clients
- `Order` - Commandes
- `OrderLine` - Lignes de commande
- `Invoice` - Factures
- `Fulfillment` - Expeditions
- `FulfillmentService` - Services d'expedition
- `Resource` - Ressources

## Services (job queues, cache servers, etc.)

L'application utilise :

- **Solid Queue** - Gestion des jobs en arriere-plan
- **Solid Cache** - Cache applicatif
- **Solid Cable** - WebSockets avec Action Cable

## Deploiement

L'application est configuree pour le deploiement avec **Kamal** (Docker).

```bash
kamal setup
kamal deploy
```

## Gems notables

- `turbo-rails` / `stimulus-rails` - Hotwire pour les interactions dynamiques
- `slim-rails` - Templates Slim
- `kaminari` - Pagination
- `draper` - Decorateurs
- `propshaft` - Pipeline d'assets moderne
