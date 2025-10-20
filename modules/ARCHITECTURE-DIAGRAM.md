# Architecture Diagram: App Service Plan Separation

## Before Refactoring

```
┌─────────────────────────────────────────────────────────────┐
│  EVO-TASKERS PROJECT                                        │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌───────────────┐      ┌───────────────┐                 │
│  │  Dashboard    │      │  SendGrid     │                 │
│  │  Function     │      │  Function     │                 │
│  ├───────────────┤      ├───────────────┤                 │
│  │ Creates own   │      │ Creates own   │                 │
│  │ EP1 Plan      │      │ EP1 Plan      │                 │
│  │ $150/mo       │      │ $150/mo       │                 │
│  └───────────────┘      └───────────────┘                 │
│                                                             │
│  ┌───────────────┐      ┌───────────────┐                 │
│  │  AutoOpenShoreX│     │ AutoDataFeed  │                 │
│  │  Function     │      │  Function     │                 │
│  ├───────────────┤      ├───────────────┤                 │
│  │ Creates own   │      │ Creates own   │                 │
│  │ EP1 Plan      │      │ EP1 Plan      │                 │
│  │ $150/mo       │      │ $150/mo       │                 │
│  └───────────────┘      └───────────────┘                 │
│                                                             │
│  ┌───────────────┐                                         │
│  │ UnlockBookings│                                         │
│  │  Logic App    │                                         │
│  ├───────────────┤                                         │
│  │ Creates own   │                                         │
│  │ WS1 Plan      │                                         │
│  │ $225/mo       │                                         │
│  └───────────────┘                                         │
│                                                             │
│  TOTAL COST: $825/month                                    │
└─────────────────────────────────────────────────────────────┘

Issues:
❌ High cost - Each app has its own plan
❌ Resource waste - Plans may be underutilized
❌ Inflexible - Can't easily share or reuse plans
```

## After Refactoring - Shared Plans

```
┌─────────────────────────────────────────────────────────────────────┐
│  EVO-TASKERS PROJECT                                                │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │  COMMON MODULE - Shared Infrastructure                      │   │
│  ├─────────────────────────────────────────────────────────────┤   │
│  │                                                             │   │
│  │  ┌────────────────────────────────────────────────────┐    │   │
│  │  │  Shared Windows Function Plan (EP2)                │    │   │
│  │  │  Autoscaling: 1-5 instances                        │    │   │
│  │  │  Cost: $300/month                                  │    │   │
│  │  └────────────────────────────────────────────────────┘    │   │
│  │         ▲          ▲            ▲            ▲             │   │
│  │         │          │            │            │             │   │
│  │  ┌──────┴───┐ ┌───┴─────┐ ┌───┴──────┐ ┌──┴──────────┐   │   │
│  │  │Dashboard │ │SendGrid │ │AutoOpen  │ │AutoDataFeed │   │   │
│  │  │Function  │ │Function │ │ShoreX    │ │Function     │   │   │
│  │  └──────────┘ └─────────┘ └──────────┘ └─────────────┘   │   │
│  │                                                             │   │
│  │  ┌────────────────────────────────────────────────────┐    │   │
│  │  │  Shared Logic App Plan (WS1)                       │    │   │
│  │  │  Cost: $225/month                                  │    │   │
│  │  └────────────────────────────────────────────────────┘    │   │
│  │         ▲                                                   │   │
│  │         │                                                   │   │
│  │  ┌──────┴────────┐                                         │   │
│  │  │UnlockBookings │                                         │   │
│  │  │Logic App      │                                         │   │
│  │  └───────────────┘                                         │   │
│  │                                                             │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                                                                     │
│  TOTAL COST: $525/month                                             │
│  SAVINGS: $300/month (36% reduction)                                │
└─────────────────────────────────────────────────────────────────────┘

Benefits:
✅ Lower cost - Share plans across similar apps
✅ Better resource utilization - Plans scale with aggregate load
✅ Flexible - Can choose different plans for different workloads
✅ Autoscaling - Handle traffic spikes automatically
```

## Alternative: Isolated Plans per App (Still Supported)

```
┌─────────────────────────────────────────────────────────────┐
│  DEVELOPMENT ENVIRONMENT                                    │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌───────────────┐      ┌───────────────┐                 │
│  │  Dashboard    │      │  SendGrid     │                 │
│  │  Function     │      │  Function     │                 │
│  ├───────────────┤      ├───────────────┤                 │
│  │ Own Y1 Plan   │      │ Own Y1 Plan   │                 │
│  │ Consumption   │      │ Consumption   │                 │
│  │ Pay-per-use   │      │ Pay-per-use   │                 │
│  └───────────────┘      └───────────────┘                 │
│                                                             │
│  Each dev app has isolated Consumption plan                │
│  Cost: Only when executing (lowest dev cost)               │
└─────────────────────────────────────────────────────────────┘
```

## Mixed Strategy: Best of Both Worlds

```
┌─────────────────────────────────────────────────────────────────────┐
│  PRODUCTION ENVIRONMENT - MIXED STRATEGY                            │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌────────────────────────────────────────────────────────┐        │
│  │  Critical Workloads - High-Performance Plan (EP3)      │        │
│  │  Zone Redundant, Always-On                             │        │
│  │  Cost: $600/month                                      │        │
│  └────────────────────────────────────────────────────────┘        │
│         ▲                    ▲                                      │
│         │                    │                                      │
│  ┌──────┴────────┐    ┌─────┴──────┐                              │
│  │ Payment       │    │ Auth       │                              │
│  │ Processing    │    │ Service    │                              │
│  └───────────────┘    └────────────┘                              │
│                                                                     │
│  ┌────────────────────────────────────────────────────────┐        │
│  │  Standard Workloads - Shared Plan (EP1)                │        │
│  │  Autoscaling enabled                                   │        │
│  │  Cost: $150/month                                      │        │
│  └────────────────────────────────────────────────────────┘        │
│         ▲          ▲            ▲                                   │
│         │          │            │                                   │
│  ┌──────┴───┐ ┌───┴─────┐ ┌───┴──────┐                            │
│  │Dashboard │ │Reporting│ │Analytics │                            │
│  └──────────┘ └─────────┘ └──────────┘                            │
│                                                                     │
│  ┌───────────────┐                                                 │
│  │ Batch Jobs    │                                                 │
│  ├───────────────┤                                                 │
│  │ Own Y1 Plan   │   ← Runs infrequently                          │
│  │ Consumption   │   ← Pay only when running                      │
│  └───────────────┘                                                 │
│                                                                     │
│  TOTAL COST: $750/month + consumption                               │
│  Optimized for: Performance + Cost                                  │
└─────────────────────────────────────────────────────────────────────┘

Strategy:
✅ Critical apps → High-tier isolated plan (performance)
✅ Standard apps → Shared mid-tier plan (cost efficiency)
✅ Batch/scheduled → Consumption plan (pay-per-use)
```

## Module Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│  TERRAFORM MODULES STRUCTURE                                        │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌───────────────────────────────────────────────────────────┐     │
│  │  app_service_plan (NEW)                                   │     │
│  ├───────────────────────────────────────────────────────────┤     │
│  │  • Creates standalone App Service Plans                   │     │
│  │  • Supports Windows & Linux                               │     │
│  │  • Optional autoscaling                                   │     │
│  │  • Zone redundancy support                                │     │
│  │  • Outputs: id, name, sku, os_type                        │     │
│  └───────────────────────────────────────────────────────────┘     │
│                              │                                      │
│                              │ Plan ID                              │
│                              ▼                                      │
│  ┌───────────────────────────────────────────────────────────┐     │
│  │  App Modules (UPDATED)                                    │     │
│  ├───────────────────────────────────────────────────────────┤     │
│  │                                                           │     │
│  │  ┌──────────────────┐  ┌──────────────────┐              │     │
│  │  │linux_function_app│  │windows_function  │              │     │
│  │  ├──────────────────┤  │_app              │              │     │
│  │  │ Mode 1:          │  ├──────────────────┤              │     │
│  │  │ Create own plan  │  │ Mode 1:          │              │     │
│  │  │                  │  │ Create own plan  │              │     │
│  │  │ Mode 2:          │  │                  │              │     │
│  │  │ Use existing     │  │ Mode 2:          │              │     │
│  │  │ plan ID          │  │ Use existing     │              │     │
│  │  └──────────────────┘  │ plan ID          │              │     │
│  │                        └──────────────────┘              │     │
│  │                                                           │     │
│  │  ┌──────────────────┐  ┌──────────────────┐              │     │
│  │  │logic_app_standard│  │linux_web_app     │              │     │
│  │  ├──────────────────┤  ├──────────────────┤              │     │
│  │  │ Mode 1:          │  │ Mode 1:          │              │     │
│  │  │ Create own plan  │  │ Create own plan  │              │     │
│  │  │                  │  │                  │              │     │
│  │  │ Mode 2:          │  │ Mode 2:          │              │     │
│  │  │ Use existing     │  │ Use existing     │              │     │
│  │  │ plan ID          │  │ plan ID          │              │     │
│  │  └──────────────────┘  └──────────────────┘              │     │
│  │                                                           │     │
│  │  New Variables:                                           │     │
│  │  • create_service_plan (bool, default: true)             │     │
│  │  • existing_service_plan_id (string, default: null)      │     │
│  │                                                           │     │
│  └───────────────────────────────────────────────────────────┘     │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

## Decision Tree: When to Share Plans?

```
                    ┌─────────────────────┐
                    │  Should I share     │
                    │  App Service Plans? │
                    └──────────┬──────────┘
                               │
              ┌────────────────┴────────────────┐
              │                                 │
              ▼                                 ▼
    ┌──────────────────┐             ┌──────────────────┐
    │ Do apps have     │             │ Apps have very   │
    │ similar scaling  │ YES         │ different        │ NO
    │ patterns?        ├─────┐       │ scaling needs?   ├────┐
    └──────────────────┘     │       └──────────────────┘    │
              │              │                 │             │
             NO              ▼                NO             ▼
              │       ┌────────────┐           │      ┌────────────┐
              │       │ SHARE      │           │      │ SEPARATE   │
              │       │ PLANS      │           │      │ PLANS      │
              │       │            │           │      │            │
              │       │ ✅ Lower   │           │      │ ✅ Isolation│
              │       │    cost    │           │      │ ✅ Custom   │
              │       │ ✅ Simpler │           │      │    scaling  │
              │       │    mgmt    │           │      └────────────┘
              │       └────────────┘           │
              │                                │
              ▼                                ▼
    ┌──────────────────┐             ┌──────────────────┐
    │ Apps in same     │             │ Critical app that│
    │ failure domain   │ YES         │ needs isolation? │ YES
    │ OK?              ├─────┐       │                  ├────┐
    └──────────────────┘     │       └──────────────────┘    │
              │              │                 │             │
             NO              ▼                NO             ▼
              │       ┌────────────┐           │      ┌────────────┐
              │       │ SHARE      │           │      │ SEPARATE   │
              │       │ PLANS      │           │      │ PLANS      │
              └───────┤            │           └──────┤            │
                      │ + Monitor  │                  │ For        │
                      │   metrics  │                  │ isolation  │
                      └────────────┘                  └────────────┘

Examples:

SHARE PLANS:
• Dashboard, reporting, analytics (similar web traffic)
• Multiple backend APIs with similar load
• Dev/test apps in same environment
• Scheduled jobs running at different times

SEPARATE PLANS:
• Critical payment vs. non-critical logging
• Public website vs. internal tools
• CPU-intensive vs. I/O-intensive workloads
• Production vs. development
```

## Cost Comparison Matrix

```
┌────────────────────────────────────────────────────────────────┐
│  Scenario: 5 Windows Function Apps                            │
├────────────────────────────────────────────────────────────────┤
│                                                                │
│  Option 1: Individual Plans (Y1 Consumption)                  │
│  ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐               │
│  │ Y1   │ │ Y1   │ │ Y1   │ │ Y1   │ │ Y1   │               │
│  └──────┘ └──────┘ └──────┘ └──────┘ └──────┘               │
│  Cost: Pay per execution (variable, low for dev/test)         │
│  Best for: Development, sporadic workloads                     │
│                                                                │
│  Option 2: Individual Plans (EP1 Premium)                     │
│  ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐               │
│  │ EP1  │ │ EP1  │ │ EP1  │ │ EP1  │ │ EP1  │               │
│  └──────┘ └──────┘ └──────┘ └──────┘ └──────┘               │
│  Cost: 5 × $150 = $750/month                                  │
│  Best for: Maximum isolation                                   │
│                                                                │
│  Option 3: Shared Plan (EP2)                                  │
│  ┌────────────────────────────────────────┐                   │
│  │ EP2 (5 apps)                           │                   │
│  └────────────────────────────────────────┘                   │
│  Cost: $300/month                                             │
│  Savings: $450/month (60%)                                    │
│  Best for: Similar workloads, cost optimization                │
│                                                                │
│  Option 4: Shared Plan with Autoscaling (EP1)                │
│  ┌────────────────────────────────────────┐                   │
│  │ EP1 (autoscale 1-5 instances)          │                   │
│  └────────────────────────────────────────┘                   │
│  Cost: $150-$750/month (based on load)                        │
│  Savings: Variable, optimal for traffic patterns              │
│  Best for: Variable workload, automatic scaling                │
│                                                                │
└────────────────────────────────────────────────────────────────┘
```

## Legend

```
▲  = References / Uses
─  = Connection
│  = Vertical flow
┌─┐= Container / Module
✅ = Benefit / Advantage
❌ = Issue / Problem
→  = Direction of flow
```

