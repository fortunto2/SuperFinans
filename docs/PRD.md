# SuperFinans — PRD (Product Requirements Document)

## Контекст

Исследование в корне проекта выявило незанятую нишу на рынке iOS-финансов: **ни один конкурент не совмещает семейный трекинг целей, offline-first архитектуру, on-device AI и разовую покупку**. YNAB — $109/год, Monarch — $100/год, Copilot — $95/год. 41% пользователей устали от подписок, 60% бюджетных приложений передают данные третьим сторонам. Apple Foundation Models (iOS 26) позволяет давать AI-инсайты без передачи данных с устройства.

Для авторизации и покупок используется готовый модуль **SuperDuperAiAuth** (`/Users/alina/projects/SuperDuperAi/packages/auth-ios/`). Архитектура строится по паттернам **FaceAlarm** (`/Users/alina/projects/FaceAlarm/ios-app/FaceAlarm/`).

---

## 1. Продукт

**Одна строка:** Offline-first семейный трекер финансовых целей для iOS с расчётом сложного процента, on-device AI и разовой оплатой $29.99.

**App Store subtitle:** "Family Savings Goals & Budget — Offline, Private, No Subscription"

**Аудитория:** Англоязычные миллениалы (28–42) с семьями в US/UK/Canada/Australia, уставшие от подписок. Вторичная: Gen Z (22–28), строящие первые финансовые цели.

**Ключевые дифференциаторы:**
1. Цели со сложным процентом — главная фича, а не приложение к бюджетированию
2. Offline-first: "Работает без интернета, данные не покидают устройство"
3. On-device AI (Foundation Models) — без облака
4. $29.99 разово vs $75–110/год у конкурентов
5. Семейный sync через CloudKit с ролями (родители видят всё, дети — только свои цели)
6. Прогрессивная сложность — первая цель за 60 секунд

---

## 2. Персоны

**Сара (34, Denver)** — мама двоих детей. Ушла из YNAB из-за подписки, сидит на Google Sheets. Хочет: 4 цели (emergency, отпуск, машина, колледж), расчёт сложного процента для колледж-фонда, чтобы дети видели прогресс цели отпуска на общем iPad.

**Маркус (29, London)** — разработчик, privacy-first. Использует self-hosted Actual Budget. Хочет: цели с compound interest, мульти-валюту (GBP/EUR), CSV-импорт из Monzo, AI-инсайты без облака.

**Прия (24, Sydney)** — первая работа. Пробовала YNAB — сдалась после 3 попыток. Хочет: одну цель с датой, понять сколько откладывать в месяц, без сложного интерфейса.

**Семья Чен (Vancouver)** — родители + подросток + бабушка. Платят $200/год за два аккаунта Monarch. Хочет: общий emergency-fund для всех, приватную цель пенсии для родителей, упрощённый вид для бабушки на iPad.

---

## 3. Фичи по релизам

### MVP (v1.0) — "Goal Tracker That Just Works"

**Goals (Hero Feature)**
- Создание целей: название, сумма, дата, текущий баланс, иконка (SF Symbol), цвет
- Расчёт сложного процента: ожидаемая годовая ставка → кривая роста (line chart)
- Калькулятор: "Откладывай $X/мес чтобы достичь цели к [дате]"
- Анимированный progress ring с процентом и суммой
- Drag-to-reorder приоритет целей
- Milestones: 25%, 50%, 75%, 100% с celebration-анимацией
- "What-if" слайдер: меняй ежемесячный вклад — видь как сдвигается дата
- Ручной лог депозитов/снятий с датой и заметкой

**Базовый трекинг расходов**
- Quick-add: сумма (numpad-first), категория, дата, заметка, счёт
- 20 предустановленных категорий с SF Symbol иконками
- Ежемесячная сводка по категориям (bar chart)
- До 3 счетов в free tier (checking, savings, credit card)
- Running balance по счёту
- Шаблоны повторяющихся транзакций (аренда, зарплата)

**On-device storage**
- Core Data с программатической моделью (без `.xcdatamodeld`, как в FaceAlarm `PersistenceController.swift`)
- iCloud sync для одного пользователя через `NSPersistentCloudKitContainer` private database
- Экспорт данных в JSON

**Onboarding**
- 3 экрана (паттерн FaceAlarm `OnboardingView`):
  1. "Track Your Financial Goals" — анимация заполнения progress ring
  2. "See Your Money Grow" — анимация графика compound interest
  3. "Private by Design" — иконка замка + "Your data stays on your device"
- После onboarding: сразу "Create Your First Goal" (не настройка бюджета!)

**Settings**
- Выбор валюты (150+ через ISO 4217)
- Внешний вид: light/dark/system
- Экспорт данных
- Account section через `AuthSettingsSection` из SuperDuperAiAuth

### v1.1 — "Family and Intelligence"

- **Family sync** — CloudKit Zone Sharing, до 6 членов, роли (admin/member/kid), per-goal sharing
- **CSV import** — CodableCSV, профили банков (Chase, Monzo, Revolut и др.), custom column mapping
- **Multi-currency** — Int64 minor units + ISO 4217, курсы от ECB, offline fallback
- **AI insights** — Foundation Models: monthly summary, goal narrative, anomaly detection, savings tips
- Fallback: Foundation Models → rule-based templates → без AI

### v2.0 — "Platform Expansion"

- Widgets (Home Screen, Lock Screen, Interactive)
- Apple Watch (quick-add, goal progress glance)
- Advanced analytics (12-month trends, year-over-year, net worth)
- Budget envelopes (opt-in, не по умолчанию)
- Shortcuts/Siri интеграция
- iPad multi-column layout

---

## 4. Информационная архитектура

4 таба (паттерн FaceAlarm `MainTabView`):

```
Tab 1: Goals (star.fill)              ← Главный таб, выбран по умолчанию
  GoalsListView → GoalCardView (ring + название + сумма + %)
  GoalDetailView → ProjectionChartView + ContributionSlider + GoalHistoryList
  CreateGoalView (sheet)

Tab 2: Transactions (list.bullet.rectangle.portrait)
  TransactionsListView (по датам) → TransactionRow
  AddTransactionView (sheet, numpad-first)
  CategoryFilterView

Tab 3: Insights (chart.bar.fill)
  InsightsDashboardView → SpendingByCategoryChart + MonthlyTrendChart
  AIInsightCard (Premium)
  GoalProjectionsView (все цели на одном графике)

Tab 4: Settings (gearshape.fill)
  AccountSection (AuthSettingsSection из SuperDuperAiAuth)
  PurchaseSection → PaywallView
  CurrencySection, FamilySyncSection, DataSection, AppearanceSection, AboutSection
```

**Навигация:** TabView → NavigationStack внутри каждого таба → .sheet для create/edit → .fullScreenCover для onboarding и paywall.

**Deep linking:** `superfinans://goal/{id}`, `superfinans://add-transaction`

---

## 5. Data Model — Core Data Entities

Программатическая модель (как FaceAlarm `PersistenceController.createManagedObjectModel()`), контейнер `NSPersistentCloudKitContainer`.

**AccountEntity** — id (UUID), name, type (checking/savings/credit/cash), currencyCode (ISO 4217), balanceMinorUnits (Int64), iconName, colorHex, sortOrder, isArchived, createdAt, updatedAt, lastModifiedBy → relationships: transactions (to-many), goals (to-many)

**TransactionEntity** — id, amountMinorUnits (Int64, positive=income, negative=expense), currencyCode, categoryId, note, date, isRecurring, recurringRuleId, createdAt, updatedAt, lastModifiedBy → relationships: account (to-one), goal (optional to-one)

**GoalEntity** — id, name, targetAmountMinorUnits (Int64), currentAmountMinorUnits, currencyCode, targetDate (optional), annualInterestRate (Decimal), compoundingFrequency, monthlyContributionMinorUnits, iconName, colorHex, sortOrder, isArchived, sharingLevel (private/family/specific), sharedWithMemberIds, createdAt, updatedAt, lastModifiedBy → relationships: account (optional to-one), deposits (to-many TransactionEntity)

**BudgetEntity** (v1.1+) — id, categoryId, limitAmountMinorUnits, currencyCode, period (monthly/weekly), startDate, isActive, createdAt, updatedAt

**RecurringRuleEntity** — id, templateAmountMinorUnits, currencyCode, categoryId, note, frequency (weekly/biweekly/monthly/yearly), dayOfMonth, dayOfWeek, nextDueDate, isActive → relationships: account (to-one), transactions (to-many)

**FamilyMemberEntity** (v1.1+) — id, cloudKitUserId, displayName, role (admin/member/kid), avatarEmoji, joinedAt, isActive

**ExchangeRateEntity** (v1.1+) — id, baseCurrency, targetCurrency, rateNumerator (Int64), rateDenominator (Int64), fetchDate

**Value type Money (Swift struct, не Core Data):**
```swift
struct Money: Equatable, Hashable, Codable, Sendable {
    let minorUnits: Int64       // 12345 = $123.45
    let currencyCode: String    // ISO 4217
    var formatted: String       // Decimal.formatted(.currency(code:))
}
```

---

## 6. Техническая архитектура

### Стек

| Слой | Технология |
|------|-----------|
| UI | SwiftUI |
| Data | Core Data + `NSPersistentCloudKitContainer` |
| Auth + покупки | SuperDuperAiAuth (local SPM package) |
| Расчёты | `FinancialCalculator` на `Decimal` / `NSDecimalNumber` |
| CSV import | CodableCSV |
| AI | Foundation Models framework |
| Валюта | Custom `Money` type (Int64 minor units) |

### Структура проекта (паттерн FaceAlarm)

```
SuperFinans/
├── App/
│   ├── SuperFinansApp.swift          // @main, onboarding gate, SuperDuperAiAuth.configure()
│   └── AppDelegate.swift             // Background fetch, CloudKit notifications
├── Models/
│   ├── Money.swift
│   ├── CategoryDefinition.swift      // Enum 20 категорий с SF Symbols
│   ├── GoalProjection.swift
│   ├── BankCSVProfile.swift
│   └── AIGenerable/                  // @Generable structs для Foundation Models
├── Persistence/
│   ├── PersistenceController.swift   // NSPersistentCloudKitContainer, программатическая модель
│   └── *Entity+CoreData.swift        // Entity classes + fetch requests
├── Services/                         // Singleton pattern: .shared
│   ├── GoalService.swift
│   ├── TransactionService.swift
│   ├── AccountService.swift
│   ├── FinancialCalculator.swift     // Compound interest, Decimal math
│   ├── CurrencyService.swift
│   ├── CSVImportService.swift
│   ├── AIInsightService.swift        // Foundation Models wrapper
│   ├── FamilySyncService.swift       // CloudKit Zone Sharing
│   ├── ExportService.swift
│   └── NotificationService.swift
├── ViewModels/                       // @MainActor, ObservableObject, @Published
│   ├── GoalsViewModel.swift
│   ├── GoalDetailViewModel.swift
│   ├── TransactionsViewModel.swift
│   ├── InsightsViewModel.swift
│   └── AddTransactionViewModel.swift
├── Views/
│   ├── MainTabView.swift             // 4-tab navigation
│   ├── Onboarding/
│   ├── Goals/                        // GoalsListView, GoalCardView, GoalDetailView, CreateGoalView, ProjectionChartView
│   ├── Transactions/                 // TransactionsListView, AddTransactionView, NumpadView, CategoryPickerView
│   ├── Insights/                     // InsightsDashboardView, AIInsightCardView, charts
│   ├── Settings/                     // SettingsView, FamilyManagementView, CSVImportView
│   ├── Paywall/                      // SuperFinansPaywallView (wraps PaywallView из SuperDuperAiAuth)
│   └── Components/                   // ProgressRingView, MoneyTextField, PremiumBadgeView, EmptyStateView
└── Extensions/
    ├── Color+Theme.swift             // Палитра (hex init, mint, navy, gradients)
    ├── View+Extensions.swift         // .if(), .card(), .pulse()
    ├── Date+Extensions.swift
    └── Decimal+Financial.swift       // pow() через NSDecimalNumber
```

### Ключевые паттерны (из FaceAlarm)

- **Singleton Services:** `@MainActor final class GoalService: ObservableObject { static let shared = GoalService() }`
- **ViewModels:** `@MainActor final class GoalDetailViewModel: ObservableObject` с `@Published` properties
- **App Entry:** `@main struct SuperFinansApp: App` с `@UIApplicationDelegateAdaptor`, `@AppStorage("onboarding_completed")`, `scenePhase`
- **Persistence:** Программатическая Core Data модель, `automaticallyMergesChangesFromParent = true`, `mergePolicy = .mergeByPropertyObjectTrump`
- **Notification-based comm:** `Notification.Name.goalMilestoneReached`, `.familyActivityUpdate`

---

## 7. Интеграция SuperDuperAiAuth

**Подключение:** Local SPM package → `/Users/alina/projects/SuperDuperAi/packages/auth-ios/`

**Конфигурация в `SuperFinansApp.init()`:**
```swift
SuperDuperAiAuth.configure(
    appId: "superfinans",
    iosClientId: "xxx.apps.googleusercontent.com",
    products: [ProductConfig(id: "superfinans.premium.lifetime", tier: .lifetime)]
)
```

**StoreKit продукт:** `superfinans.premium.lifetime` — Non-consumable, $29.99, tier `.lifetime`

**Sign-in — опционален.** Приложение полностью работает без авторизации. Sign-in нужен только для:
- Supabase-аккаунт (будущий web dashboard в v2.0+)
- Профиль пользователя

**iCloud sync** работает через Apple ID системы (не через SuperDuperAiAuth).

**Paywall:** `SuperFinansPaywallView` оборачивает `PaywallView` из SuperDuperAiAuth с кастомной `SuperFinansPaywallTheme` (navy + mint цвета). Показывается как `.sheet` при попытке:
- Создать 2-ю цель
- Открыть Family в Settings
- Нажать AI insight card
- Импортировать CSV
- Сменить валюту

**Проверка Premium:**
```swift
SuperDuperAiAuth.shared.subscription.tier == .lifetime
```

**AccountView** в Settings через `AuthSettingsSection` из SuperDuperAiAuth (sign out, delete account, subscription status).

---

## 8. AI Features (Foundation Models)

**Три уровня доступности:**
1. `foundationModels` — iPhone 15 Pro+, iOS 26, Apple Intelligence включён
2. `ruleBased` — старые устройства, шаблонные инсайты
3. `unavailable` — AI недоступен

**Use cases с Guided Generation (`@Generable`):**

| Use case | Input (pre-aggregated в Swift) | Output struct |
|----------|------|--------|
| Monthly spending summary | totalSpent, top 5 categories с % change | `SpendingSummary { narrative, biggestIncrease, savingsTip }` |
| Goal progress narrative | goal name, %, pace vs plan | `GoalNarrative { message, status: GoalStatus }` |
| Transaction categorization | merchant name, amount, note | `CategorySuggestion { category: SpendingCategory, confidence }` |
| Anomaly detection | category, current vs 3-month avg | `AnomalyInsight { description, sentiment }` |

**Правило:** Все расчёты — в Swift на `Decimal`. Модель только генерирует текст и классифицирует. Контекстное окно 4096 токенов — передаём только агрегированные данные, не сырые транзакции.

**Rule-based fallback:** Шаблонные строки с подставленными числами: "This month you spent $X, up Y% from last month. Top category: Z at $W."

---

## 9. Progressive Disclosure

| Когда | Что открывается |
|-------|-----------------|
| Первый запуск (0–60 сек) | Onboarding → Create first goal (только name + amount + date) |
| Первая неделя | Goals tab — депозиты, milestones. Compound interest по тапу "Want to see your money grow?" |
| 3+ депозита | Подсказка: "Track spending to find more money for goals" → активация Transactions tab |
| 10+ транзакций | Предложение бюджета: "Set a limit for [top category]?" |
| 1 месяц данных | AI insight card в Insights (Premium teaser) |
| 2+ цели | What-if слайдер на GoalDetailView |
| 20+ транзакций | CSV import появляется в Settings > Data |
| 2+ недели | Family sync появляется в Settings |

Реализация: `FeatureDiscoveryFlags` в UserDefaults + TipKit (iOS 17+) для inline-подсказок.

---

## 10. Free vs Premium

| | Free | Premium ($29.99) |
|--|------|-------------------|
| Цели | 1 | Unlimited |
| Счета | 3 | Unlimited |
| Транзакции | Unlimited | Unlimited |
| Категории | 20 built-in | + custom |
| Бюджеты | 5 | Unlimited |
| Recurring rules | 3 | Unlimited |
| Отчёты | Текущий месяц | 12 месяцев |
| CSV import | — | ✅ |
| Multi-currency | — | ✅ |
| Family sync | — | До 6 чел |
| AI insights | — | ✅ |
| iCloud sync (personal) | ✅ | ✅ |
| Реклама / трекинг | Нет | Нет |

---

## 11. Метрики успеха

**North Star:** Weekly Active Goal Engagers (WAGE) — пользователи, взаимодействующие с целями каждую неделю.

| Метрика | Цель M1 | Цель M6 | Цель M12 |
|---------|---------|---------|----------|
| Downloads | 2,000 | 8,000 | 20,000 |
| Day 1 retention | 40% | 45% | 50% |
| Day 7 retention | 25% | 30% | 35% |
| Free→Premium conversion | 3% | 5% | 5% |
| Time to first goal | < 90 сек | < 60 сек | < 60 сек |
| App Store rating | 4.5+ | 4.7+ | 4.7+ |
| Monthly net revenue (after Apple 15%) | $1,530 | $10,200 | $25,500 |

---

## 12. Порядок реализации (Sprint Plan)

### Sprint 1 — Фундамент (2 недели)
1. Создать Xcode проект, подключить SuperDuperAiAuth как local SPM package
2. `PersistenceController` — программатическая Core Data модель (AccountEntity, TransactionEntity, GoalEntity, RecurringRuleEntity) + `NSPersistentCloudKitContainer`
3. `Money` struct, `CategoryDefinition` enum
4. `FinancialCalculator` — compound interest, monthly contribution, months-to-goal
5. `Color+Theme`, `View+Extensions`, `Date+Extensions`

### Sprint 2 — Goals (Hero Feature) (2 недели)
1. `GoalService`, `GoalsViewModel`, `GoalDetailViewModel`
2. `GoalsListView`, `GoalCardView`, `ProgressRingView`
3. `CreateGoalView` (sheet)
4. `GoalDetailView` с `ProjectionChartView` (Swift Charts) и `ContributionSliderView`
5. Milestone animations (25/50/75/100%)
6. Deposit/withdrawal logging per goal

### Sprint 3 — Transactions + Navigation (2 недели)
1. `TransactionService`, `AccountService`, `TransactionsViewModel`
2. `MainTabView` (4 таба)
3. `AddTransactionView` с `NumpadView`, `CategoryPickerView`
4. `TransactionsListView` с группировкой по датам
5. Recurring transactions (`RecurringRuleEntity`, `RecurringTransactionService`)

### Sprint 4 — Insights + Onboarding + Paywall (2 недели)
1. `InsightsViewModel`, `InsightsDashboardView`
2. `SpendingByCategoryChart`, `MonthlyTrendChart` (Swift Charts)
3. `OnboardingView` (3 экрана)
4. `SuperFinansPaywallView` + `SuperFinansPaywallTheme`
5. Premium checks по всему приложению
6. Settings page с `AuthSettingsSection`

### Sprint 5 — Polish + MVP Release (1 неделя)
1. Progressive disclosure (`FeatureDiscoveryFlags`)
2. JSON export
3. Deep linking
4. Edge cases, empty states, loading states
5. TestFlight → App Store submit

### Sprint 6-8 — v1.1 Features (6 недель)
1. `AIInsightService` + Foundation Models integration
2. `FamilySyncService` + CloudKit Zone Sharing
3. `CSVImportService` + CodableCSV
4. `CurrencyService` + multi-currency

---

## 13. Verification

- **Unit tests:** `FinancialCalculator` (compound interest accuracy), `Money` (arithmetic, formatting, currency conversion), Core Data CRUD operations
- **UI tests:** Onboarding flow → create first goal < 90 сек, paywall presentation on premium feature tap
- **Integration:** SuperDuperAiAuth configure → purchase → premium check, Core Data ↔ CloudKit sync
- **Manual:** Offline mode (airplane mode — all features work), AI insights on iPhone 15 Pro+ vs fallback на старых устройствах

---

## Ключевые файлы для повторного использования

| Файл | Что берём |
|------|----------|
| `FaceAlarm/Persistence/PersistenceController.swift` | Паттерн программатической Core Data модели, переделать под NSPersistentCloudKitContainer |
| `FaceAlarm/App/FaceAlarmApp.swift` | @main struct, onboarding gate, scenePhase, deep linking |
| `FaceAlarm/Views/MainTabView.swift` | Tab navigation, sheet/fullScreenCover presentation |
| `FaceAlarm/ViewModels/AlarmViewModel.swift` | @MainActor + @Published + service injection pattern |
| `FaceAlarm/Extensions/Color+Theme.swift` | Hex color init, палитра, градиенты |
| `FaceAlarm/Extensions/View+Extensions.swift` | Conditional modifiers, card styling |
| `SuperDuperAiAuth/SuperDuperAiAuth.swift` | configure(), isPremium, signIn/Out, purchase API |
| `SuperDuperAiAuth/Views/PaywallView.swift` | PaywallView + PaywallTheme protocol |
| `SuperDuperAiAuth/Views/AuthSettingsSection.swift` | Embeddable settings section |
