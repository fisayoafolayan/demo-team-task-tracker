# Bob Plugin Example - Team Task Tracker

A team task tracker API built with [kiln](https://github.com/fisayoafolayan/kiln) as a [bob](https://github.com/stephenafamo/bob) plugin. Demonstrates every kiln feature:

- **Users** - CRUD with unique email constraint and role enum (`member`, `admin`)
- **Projects** - CRUD with owner FK, status enum (`active`, `archived`)
- **Tasks** - CRUD with project FK, assignee FK, priority enum, soft deletes
- **Tags** - CRUD with unique name
- **Task Tags** - M2M junction table generating link/unlink endpoints

## What gets generated

```
GET    /api/v1/users                     list with filtering & sorting
POST   /api/v1/users                     create with validation
GET    /api/v1/users/{id}                get by ID
PATCH  /api/v1/users/{id}                partial update
DELETE /api/v1/users/{id}                delete

GET    /api/v1/projects                  list
POST   /api/v1/projects                  create
GET    /api/v1/users/{id}/projects       nested route from owner FK

GET    /api/v1/tasks                     list (soft-deleted excluded)
DELETE /api/v1/tasks/{id}                soft delete (sets deleted_at)
GET    /api/v1/projects/{id}/tasks       nested route from project FK
GET    /api/v1/users/{id}/tasks          nested route from assignee FK

POST   /api/v1/tasks/{id}/tags           link a tag to a task (M2M)
DELETE /api/v1/tasks/{id}/tags/{tagId}   unlink a tag from a task
GET    /api/v1/tasks/{id}/tags           list tags for a task

POST   /api/v1/tags/{id}/tasks           link a task to a tag (reverse)
DELETE /api/v1/tags/{id}/tasks/{taskId}  unlink a task from a tag
GET    /api/v1/tags/{id}/tasks           list tasks for a tag
```

Plus OpenAPI spec at `docs/openapi.yaml`.

## When to use the plugin approach

Most users should use `kiln generate` (the standalone CLI). Use the plugin approach when:

- You already use bob directly in your project
- You want to customize bob's generation pipeline
- You want a single `go run` command instead of installing kiln

## Using this in your own project

```bash
go get github.com/fisayoafolayan/kiln@latest
go get github.com/stephenafamo/bob@latest
```

The plugin is part of the main kiln module.

## Setup

```bash
cd examples/bob-plugin
cp .env.example .env
make setup
make run
```

Or step by step: `make help` to see all commands.

## Project Structure

```
bob-plugin/
  gen/main.go          runs bob + kiln plugin (the key file)
  cmd/server/main.go   generated server entry point (write-once)
  kiln.yaml            kiln config
  schema.sql           database schema
  docker-compose.yml   Postgres container
  .env                 DATABASE_URL
```

## The Key File: gen/main.go

```go
package main

import (
    "context"
    "log"
    "os"
    "os/signal"

    "github.com/stephenafamo/bob/gen"
    "github.com/stephenafamo/bob/gen/bobgen-psql/driver"
    "github.com/stephenafamo/bob/gen/plugins"
    kilnplugin "github.com/fisayoafolayan/kiln/plugin"
)

func main() {
    ctx, cancel := signal.NotifyContext(context.Background(), os.Interrupt)
    defer cancel()

    dsn := os.Getenv("DATABASE_URL")
    if dsn == "" {
        log.Fatal("DATABASE_URL is required")
    }

    driverCfg := driver.Config{}
    driverCfg.Dsn = dsn

    pluginsCfg := plugins.Config{}
    pluginsCfg.Models.Destination = "./models"
    pluginsCfg.Models.Pkgname = "models"
    bobPlugins := plugins.Setup[any, any, driver.IndexExtra](
        pluginsCfg, gen.PSQLTemplates,
    )

    kiln := kilnplugin.New[any, any, driver.IndexExtra](kilnplugin.Options{
        ConfigPath: "kiln.yaml",
    })

    state := &gen.State[any]{Config: gen.Config[any]{}}
    allPlugins := append(bobPlugins, kiln)

    if err := gen.Run(ctx, state, driver.New(driverCfg), allPlugins...); err != nil {
        log.Fatal(err)
    }
}
```

This is equivalent to running `kiln generate` but gives you full control over bob's pipeline.
