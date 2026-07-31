---
name: hyva-admin-dashboard-widget
description: Create or modify a Hyvä Commerce Admin Dashboard Widget in Magento 2. 
Use this skill when the user wants to create a new Hyvä Admin Dashboard Widget, add a dashboard widget to an existing module, modify or extend an existing widget, 
or needs help with any aspect of the Hyvä Admin Dashboard widget system (PHP model, XML config, templates, display types, configurable properties). 
Trigger phrases include "create hyva admin dashboard widget", "create admin dashboard widget", "create dashboard widget", 
"add hyva admin dashboard widget", "add admin dashboard widget", "add dashboard widget", 
"custom hyva admin dashboard widget", "custom admin dashboard widget", "custom dashboard widget".
requires: hyva-exec-shell-cmd, hyva-create-module
---

# Hyvä Admin Dashboard Widget

This skill creates and modifies Hyvä Commerce Admin Dashboard Widgets — custom panels that appear on the Hyvä Commerce Admin Dashboard.

## Overview

A widget consists of:
1. **`hyva_dashboard_widget.xml`** — declares the widget to the framework
2. **Widget PHP class** — extends `AbstractWidgetType` and implements `getDisplayData()`
3. **Module scaffolding** — `registration.php`, `module.xml` with the right dependency

Optionally:
- A **phtml template** (for `display_type=template`)
- A **layout file** for a custom empty-state message

---

## Workflow

### Step 1: Gather context

Ask (or infer from context):
- **Vendor** and **Module** names (PascalCase)
- **Widget ID** (snake_case, e.g. `pending_returns`)
- **Title** — human-readable title shown in the widget picker
- **Display type** — see the Display Types section below
- **What data to show** — where it comes from (repository, resource connection, etc.)
- **Optional**: category, icon, min_height/min_width, cache_lifetime, trailing action, ACL, configurable properties

If the user hasn't specified a vendor/module, ask whether this widget should go into a new module or an existing one. Widgets that belong to a specific feature naturally live in that feature's module; standalone dashboard widget collections often live in a dedicated `*AdminDashboardWidget` module.

### Step 2: Create/update the module

If a new module is needed, use the `hyva-create-module` skill with:
- `dependencies`: `["Hyva_AdminDashboardFramework"]`
- `composer_require`: {"hyva-themes/commerce-module-admin-dashboard", "^1.0"}

If adding to an existing module:
- Request the module path (can be in `app/code/`, `vendor/`, or custom location)
- Verify the module has `Hyva_AdminDashboardFramework` as a dependency in `etc/module.xml`. If not present, add it.
- Verify the module has `hyva-themes/commerce-module-admin-dashboard` as a dependency in `composer.json`. If not present, add it.

### Step 3: Create the files

Create the three required files (plus optional ones based on display type):

```
app/code/{Vendor}/{Module}/
├── registration.php           ← from hyva-create-module
├── etc/
│   ├── module.xml             ← from hyva-create-module
│   └── adminhtml/
│       └── hyva_dashboard_widget.xml   ← declare widget
└── Model/
    └── Widget/
        └── MyWidget.php       ← widget logic
```

For `display_type=template`, also create:
```
view/adminhtml/templates/widget/my-widget.phtml
```

For a custom empty state (optional):
```
view/adminhtml/layout/hyva_dashboard_widget_instance_{widget_id}.xml
view/adminhtml/templates/widget/empty/my-widget.phtml
```

### Step 4: Run setup

Use the `hyva-exec-shell-cmd` skill to run:
```bash
bin/magento setup:upgrade
```

---

## File Templates

### `etc/adminhtml/hyva_dashboard_widget.xml`

```xml
<?xml version="1.0"?>
<config xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:noNamespaceSchemaLocation="urn:magento:module:Hyva_AdminDashboardFramework:etc/adminhtml/hyva_dashboard_widget.xsd">
    <widget id="{widget_id}">
        <title>{Human Readable Title}</title>
        <category>sales</category>
        <icon>table</icon>
        <class>{Vendor}\{Module}\Model\Widget\{ClassName}</class>
        <display_type>table</display_type>
        <min_height>6</min_height>
        <cache_lifetime>300</cache_lifetime>
    </widget>
</config>
```

All XML options for `<widget>`:

| Element | Required | Notes |
|---|---|---|
| `class` | Yes | PHP class implementing the widget |
| `display_type` | Yes | See Display Types table |
| `title` | No | Shown in widget picker; defaults to class-derived name |
| `category` | No | `sales`, `customers`, `marketing`, `content`, `other` |
| `tags` | No | Comma-separated search tags |
| `icon` | No | Lucide icon name (e.g. `shopping-cart`, `chart-bar`, `table`) |
| `min_height` | No | Grid rows (integer) |
| `min_width` | No | Grid columns (integer, default 1) |
| `full_screen` | No | `true` to allow full-screen mode |
| `cache_lifetime` | No | Seconds; `0` = no cache |
| `acl` | No | ACL resource ID, e.g. `Magento_Sales::sales` |
| `template` | No | Required when `display_type=template`; format: `Vendor_Module::path/to/file.phtml` |
| `trailing_action` | No | Link shown at widget footer |

`<trailing_action>` structure:
```xml
<trailing_action>
    <label>View All Orders</label>
    <route>sales/order</route>
    <target>_self</target>  <!-- _self or _blank -->
</trailing_action>
```

---

### Widget PHP Class

All widgets extend `AbstractWidgetType` from `Hyva\AdminDashboardFramework\Model\WidgetType`.

```php
<?php
declare(strict_types=1);

namespace {Vendor}\{Module}\Model\Widget;

use Hyva\AdminDashboardFramework\Model\WidgetAuth;
use Hyva\AdminDashboardFramework\Model\WidgetConfig;
use Hyva\AdminDashboardFramework\Model\WidgetInstance\WidgetInstanceInterface;
use Hyva\AdminDashboardFramework\Model\WidgetType\AbstractWidgetType;

class {ClassName} extends AbstractWidgetType
{
    protected string $id = '{widget_id}';  // must match the id in hyva_dashboard_widget.xml

    public function __construct(
        WidgetAuth $widgetAuth,
        WidgetConfig $widgetConfig,
        // inject your own dependencies here
        string $id = '',
        array $data = []
    ) {
        parent::__construct($widgetAuth, $widgetConfig, $id, $data);
    }

    public function getDisplayData(WidgetInstanceInterface $widgetInstance): array
    {
        // return data shaped for your display_type — see Display Types below
    }
}
```

**Key points:**
- `$id` must exactly match the `id` attribute in `hyva_dashboard_widget.xml`
- Always pass `$widgetAuth`, `$widgetConfig`, `$id`, `$data` through to `parent::__construct()`
- The `$id` and `$data` constructor parameters must come last, with empty defaults
- `getDisplayData()` is called on every dashboard page load (subject to caching)

---

## Display Types

### `table` — clickable rows with column headings

Use when showing a list of entities (orders, customers, products, etc.).

`getDisplayData()` must return:
```php
[
    'headings' => [__('Column 1'), __('Column 2'), __('Column 3')],
    'rows' => [
        [
            'href' => $this->url->getUrl('sales/order/view', ['order_id' => $id]), // optional
            'values' => ['Customer Name', 42, '$99.00'],
        ],
        // ...
    ],
]
```
Return `[]` when there is no data (triggers the empty-state template).

---

### `date-interval-table` — table with a date range selector

Extends `AbstractDateIntervalWidget`. The user can switch between time periods (today, last 7 days, last 30 days, etc.). Use for sales/activity tables that are naturally time-bounded.

```php
use Hyva\AdminDashboardFramework\Model\Widget\AbstractDateIntervalWidget;
use Hyva\AdminDashboardFramework\Model\Config\Source\WidgetDateIntervals;

class MyWidget extends AbstractDateIntervalWidget
{
    protected string $id = 'my_widget';

    public function __construct(
        WidgetAuth $widgetAuth,
        WidgetConfig $widgetConfig,
        WidgetDateIntervals $widgetDateIntervals,
        // your dependencies
        string $id = '',
        array $data = []
    ) {
        parent::__construct($widgetAuth, $widgetConfig, $widgetDateIntervals, $id, $data);
    }

    public function getDisplayData(WidgetInstanceInterface $widgetInstance): array
    {
        $intervalData = $this->getIntervalData(); // available intervals with timestamps
        // filter your data by $intervalData[0]['interval_time'] (earliest timestamp)
        // return same shape as table display type
    }
}
```

Use `display_type=date-interval-table` in XML.

---

### `template` — fully custom phtml template

Use when none of the built-in display types fit (charts, maps, complex layouts).

Set `display_type=template` and `<template>Vendor_Module::widget/my-widget.phtml</template>` in XML.

`getDisplayData()` can return any shape — your template receives it via `$block->getDisplayData($widgetInstance)`.

Template skeleton:
```php
<?php
declare(strict_types=1);

use Hyva\AdminDashboardFramework\Block\Adminhtml\Widget\WidgetInstance;
use Magento\Framework\Escaper;

/** @var WidgetInstance $block */
/** @var Escaper $escaper */

$data = $block->getDisplayData($block->getWidgetInstance());
?>
<div>
    <?= $escaper->escapeHtml($data['my_value'] ?? '') ?>
</div>
```

---

### `number` — single KPI number

Extend `AbstractNumber` (`Hyva\AdminDashboardFramework\Model\Widget\AbstractNumber`).
Return a numeric value from `getDisplayData()`.

---

### `line_chart` / `bar_chart` / `pie_chart`

Extend the corresponding abstract class:
- `Hyva\AdminDashboardFramework\Model\Widget\AbstractLineChart`
- `Hyva\AdminDashboardFramework\Model\Widget\AbstractBarChart`
- `Hyva\AdminDashboardFramework\Model\Widget\AbstractPieChart`

---

## Configurable Properties

Users can configure widgets when they add them to their dashboard. Override `getConfigurableProperties()` to add settings.

```php
public function getConfigurableProperties(): array
{
    return array_merge(
        parent::getConfigurableProperties(),
        [
            'row_count' => [
                'label' => __('Number of Rows'),
                'input' => [
                    'type' => 'text',
                    'attributes' => [
                        'type' => 'number',
                        'min' => 1,
                        'max' => 100,
                        'required' => true,
                        'value' => 10,
                    ],
                ],
            ],
        ]
    );
}
```

Read configured values in `getDisplayData()`:
```php
$rowCount = (int) ($widgetInstance->getPropertyValue(
    WidgetTypeInterface::KEY_CONFIGURABLE_PROPERTIES,
    'row_count'
) ?? 10);
```

Input types:
- `type: 'text'` — text/number input; use `attributes.type = 'number'` for numeric
- `type: 'select'` — dropdown; provide `options` array of `['label' => ..., 'value' => ...]`
- `type: 'scope'` — store view multi-select (built-in); add `attributes.multiple = true`

---

## Display Properties

Display properties are settings that appear in the widget *display* settings (not configuration). Override `getDisplayProperties()` — same shape as `getConfigurableProperties()`. Read them with `KEY_DISPLAY_PROPERTIES`.

---

## Custom Empty State

When `getDisplayData()` returns `[]`, the framework shows a default empty-state message. To customize it, create a layout handle:

**`view/adminhtml/layout/hyva_dashboard_widget_instance_{widget_id}.xml`:**
```xml
<?xml version="1.0"?>
<page xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
      xsi:noNamespaceSchemaLocation="urn:magento:framework:View/Layout/etc/page_configuration.xsd">
    <body>
        <referenceBlock name="widget-instance.empty"
                        template="{Vendor}_{Module}::widget/empty/{widget-id}.phtml"/>
    </body>
</page>
```

**`view/adminhtml/templates/widget/empty/{widget-id}.phtml`:**
```php
<?php
declare(strict_types=1);
use Magento\Backend\Block\Template;
use Magento\Framework\Escaper;
/** @var Template $block */
/** @var Escaper $escaper */
?>
<div class="message">
    <?= $escaper->escapeHtml(__('Nothing to show right now.')); ?>
</div>
```

---

## Complete Example: Table Widget

**Scenario**: Show the 10 most recent newsletter subscribers in a table.

### `etc/adminhtml/hyva_dashboard_widget.xml`
```xml
<?xml version="1.0"?>
<config xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:noNamespaceSchemaLocation="urn:magento:module:Hyva_AdminDashboardFramework:etc/adminhtml/hyva_dashboard_widget.xsd">
    <widget id="recent_subscribers">
        <title>Recent Newsletter Subscribers</title>
        <category>marketing</category>
        <icon>mail</icon>
        <class>Acme\Dashboard\Model\Widget\RecentSubscribers</class>
        <display_type>table</display_type>
        <min_height>6</min_height>
        <cache_lifetime>300</cache_lifetime>
        <trailing_action>
            <label>View All Subscribers</label>
            <route>newsletter/subscriber</route>
        </trailing_action>
    </widget>
</config>
```

### `Model/Widget/RecentSubscribers.php`
```php
<?php
declare(strict_types=1);

namespace Acme\Dashboard\Model\Widget;

use Hyva\AdminDashboardFramework\Model\WidgetAuth;
use Hyva\AdminDashboardFramework\Model\WidgetConfig;
use Hyva\AdminDashboardFramework\Model\WidgetInstance\WidgetInstanceInterface;
use Hyva\AdminDashboardFramework\Model\WidgetType\AbstractWidgetType;
use Magento\Newsletter\Model\ResourceModel\Subscriber\CollectionFactory;

class RecentSubscribers extends AbstractWidgetType
{
    protected string $id = 'recent_subscribers';

    public function __construct(
        WidgetAuth $widgetAuth,
        WidgetConfig $widgetConfig,
        private readonly CollectionFactory $collectionFactory,
        string $id = '',
        array $data = []
    ) {
        parent::__construct($widgetAuth, $widgetConfig, $id, $data);
    }

    public function getDisplayData(WidgetInstanceInterface $widgetInstance): array
    {
        $collection = $this->collectionFactory->create()
            ->addFieldToFilter('subscriber_status', 1)
            ->setOrder('change_status_at', 'DESC')
            ->setPageSize(10);

        if (!$collection->getSize()) {
            return [];
        }

        $data = [
            'headings' => [__('Email'), __('Subscribed At')],
            'rows' => [],
        ];

        foreach ($collection as $subscriber) {
            $data['rows'][] = [
                'values' => [
                    $subscriber->getSubscriberEmail(),
                    $subscriber->getChangeStatusAt(),
                ],
            ];
        }

        return $data;
    }
}
```

---

## Checklist

- [ ] `$id` in PHP class matches `id` attribute in XML
- [ ] `Hyva_AdminDashboardFramework` is in `<sequence>` in `module.xml`
- [ ] `display_type` in XML matches the abstract class extended (if using chart/number abstracts)
- [ ] `<template>` element present in XML when `display_type=template`
- [ ] `getDisplayData()` returns `[]` (not `null`) for the empty state
- [ ] `bin/magento setup:upgrade` has been run
