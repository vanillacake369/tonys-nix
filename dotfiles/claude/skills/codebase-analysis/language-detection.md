# Language and Technology Detection

## File Extension Mapping

### Programming Languages

**Compiled Languages:**
- `.c`, `.h` → C
- `.cpp`, `.cc`, `.cxx`, `.hpp` → C++
- `.rs` → Rust
- `.go` → Go
- `.java` → Java
- `.cs` → C#
- `.swift` → Swift

**Interpreted/Scripting:**
- `.py` → Python
- `.rb` → Ruby
- `.js`, `.mjs`, `.cjs` → JavaScript
- `.ts` → TypeScript
- `.php` → PHP
- `.lua` → Lua
- `.pl` → Perl

**Functional:**
- `.hs`, `.lhs` → Haskell
- `.ml`, `.mli` → OCaml
- `.ex`, `.exs` → Elixir
- `.erl`, `.hrl` → Erlang
- `.clj`, `.cljs` → Clojure

**JVM Languages:**
- `.kt` → Kotlin
- `.scala` → Scala
- `.groovy` → Groovy

**Systems:**
- `.asm`, `.s` → Assembly
- `.v`, `.sv` → Verilog/SystemVerilog

### Web Technologies

**Frontend:**
- `.jsx` → React (JavaScript)
- `.tsx` → React (TypeScript)
- `.vue` → Vue.js
- `.svelte` → Svelte
- `.html` → HTML
- `.css`, `.scss`, `.sass`, `.less` → Stylesheets

**Backend:**
- `.asp`, `.aspx` → ASP.NET
- `.jsp` → Java Server Pages
- `.erb` → Ruby on Rails

## Framework Detection

### Build/Config File Indicators

**JavaScript/Node.js Ecosystem:**
```bash
package.json → Node.js project
  "dependencies": {
    "react": → React
    "vue": → Vue
    "angular": → Angular
    "express": → Express
    "next": → Next.js
    "nest": → NestJS
  }

webpack.config.js → Webpack
vite.config.js → Vite
rollup.config.js → Rollup
tsconfig.json → TypeScript
```

**Python Ecosystem:**
```bash
requirements.txt → pip
setup.py → setuptools
pyproject.toml → Poetry/modern Python
Pipfile → Pipenv

# Framework detection from imports
django → Django
flask → Flask
fastapi → FastAPI
```

**Java/JVM:**
```bash
pom.xml → Maven
  <groupId>org.springframework → Spring/Spring Boot
  <groupId>jakarta.ee → Jakarta EE

build.gradle, build.gradle.kts → Gradle
  org.springframework.boot → Spring Boot
  io.micronaut → Micronaut
  io.quarkus → Quarkus
```

**Go:**
```bash
go.mod → Go modules
  github.com/gin-gonic/gin → Gin
  github.com/gorilla/mux → Gorilla
  go.uber.org/fx → Fx
```

**Rust:**
```bash
Cargo.toml → Cargo
  actix-web → Actix
  rocket → Rocket
  axum → Axum
```

**Ruby:**
```bash
Gemfile → Bundler
  rails → Ruby on Rails
  sinatra → Sinatra
```

**PHP:**
```bash
composer.json → Composer
  laravel → Laravel
  symfony → Symfony
```

### Infrastructure Detection

**Containerization:**
```bash
Dockerfile → Docker
docker-compose.yml → Docker Compose
.dockerignore → Docker
```

**Orchestration:**
```bash
*.yaml in k8s/, kubernetes/, manifests/ → Kubernetes
helm/ directory → Helm charts
skaffold.yaml → Skaffold
```

**Cloud Providers:**
```bash
.aws/ → AWS
gcloud/ → Google Cloud
azure/ → Azure
terraform/ *.tf → Terraform
pulumi/ → Pulumi
```

**CI/CD:**
```bash
.github/workflows/ → GitHub Actions
.gitlab-ci.yml → GitLab CI
.circleci/ → CircleCI
Jenkinsfile → Jenkins
.travis.yml → Travis CI
azure-pipelines.yml → Azure Pipelines
```

## Version Detection

### Language Versions

**From Config Files:**
```bash
# Python
.python-version
pyproject.toml: requires-python = ">=3.9"

# Node.js
.nvmrc
package.json: "engines": {"node": ">=18"}

# Ruby
.ruby-version
Gemfile: ruby '3.1.2'

# Java
build.gradle: sourceCompatibility = '17'
pom.xml: <maven.compiler.target>17</maven.compiler.target>

# Go
go.mod: go 1.21
```

### Framework Versions
```json
// package.json
"dependencies": {
  "react": "^18.2.0",  // Major version 18
  "next": "13.4.0"     // Exact version
}
```

## Database Detection

### Database Technology

**Relational:**
```bash
# Connection strings or configs
postgres:// → PostgreSQL
mysql:// → MySQL
mssql:// → SQL Server

# ORM configs
prisma/schema.prisma → Prisma
migrations/ + ActiveRecord → Rails with SQL
alembic/ → SQLAlchemy
```

**NoSQL:**
```bash
mongodb:// → MongoDB
redis:// → Redis
cassandra → Cassandra

# Library detection
mongoose → MongoDB (Node.js)
redis-py → Redis (Python)
```

**ORMs:**
```bash
# JavaScript/TypeScript
Sequelize, TypeORM, Prisma, Objection.js

# Python
SQLAlchemy, Django ORM, Peewee

# Java
Hibernate, JPA, MyBatis

# Ruby
ActiveRecord

# Go
GORM, sqlx
```

## Testing Framework Detection

### Test File Patterns

**JavaScript/TypeScript:**
```bash
*.test.js, *.spec.js → Jest, Mocha, Jasmine
jest.config.js → Jest
mocha.opts, .mocharc.json → Mocha
karma.conf.js → Karma
```

**Python:**
```bash
test_*.py, *_test.py → pytest, unittest
pytest.ini, pyproject.toml [tool.pytest] → pytest
conftest.py → pytest fixtures
```

**Java:**
```bash
*Test.java → JUnit, TestNG
@Test annotation → JUnit/TestNG
build.gradle: testImplementation 'org.junit.jupiter' → JUnit 5
```

**Go:**
```bash
*_test.go → Go testing
TestXxx functions → Standard go test
```

**Rust:**
```bash
#[test] → Built-in testing
#[cfg(test)] → Test modules
```

## Multi-Language Projects

### Detection Strategy

1. **Count file extensions** across project
2. **Identify primary language** (most files)
3. **Detect auxiliary languages** (configs, scripts, tests)
4. **Map relationships** (e.g., TypeScript frontend + Go backend)

### Common Patterns

**Monorepo Indicators:**
```bash
lerna.json → Lerna monorepo
nx.json → Nx monorepo
pnpm-workspace.yaml → pnpm workspaces
```

**Service Separation:**
```
frontend/ → React/Vue/Angular
backend/ → Node/Go/Java
mobile/ → React Native/Flutter
```

## Advanced Detection

### Analyzing Imports

**JavaScript/TypeScript:**
```javascript
import React from 'react'              // React
import { Component } from '@angular/core' // Angular
import Vue from 'vue'                   // Vue
```

**Python:**
```python
from django.db import models  # Django
from flask import Flask       # Flask
import tensorflow as tf       # TensorFlow
```

**Go:**
```go
import "github.com/gin-gonic/gin" // Gin framework
```

### Shebang Detection
```bash
#!/usr/bin/env python3  → Python
#!/usr/bin/env node     → Node.js
#!/bin/bash             → Bash
#!/usr/bin/env ruby     → Ruby
```

## Complete Detection Process

1. **Scan file extensions** → Primary language(s)
2. **Find build files** → Build system & dependencies
3. **Parse dependencies** → Frameworks & libraries
4. **Locate configs** → Tools, linters, formatters
5. **Check infrastructure** → Docker, K8s, cloud
6. **Identify testing** → Test frameworks
7. **Analyze imports** → Confirm framework usage
8. **Synthesize profile** → Complete tech stack

This creates a comprehensive technology profile for adapting all future work.
