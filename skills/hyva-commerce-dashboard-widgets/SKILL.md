---
name: hyva-widgets
description: Use when creating or modifying a Hyva Commerce Admin Dashboard widget for Magento Admin using the newer Hyva AdminDashboardApi V1 composition contract, including etc/adminhtml/hyva_dashboard_widget.xml registration, WidgetTypeInterface methods with WidgetContextInterface, configurable/display properties, display data, permissions, save hooks, built-in display types, and optional custom templates/scripts. Examples must be generic for app/code/Vendor/Module and not company-specific.
---

# Hyva Admin Dashboard Widgets

This skill is for **Hyva Commerce Admin Dashboard widgets**: pluggable cards
merchants add to the Magento Admin Dashboard, such as KPIs, charts, tables,
links, and custom template widgets.

It is not for generic Hyva storefront Alpine.js components. If the user asks
for an ordinary storefront `.phtml` interaction, skip this skill and follow the
nearest theme pattern instead.

Use vendor-neutral examples by default:

- PHP namespace: `Vendor\Module`
- Magento module name: `Vendor_Module`
- Module path: `app/code/Vendor/Module`

Replace those placeholders with the real module only when implementing in an
existing codebase.

## Source Of Truth

Only support the newer composition API:

- Implement `Hyva\AdminDashboardApi\Api\V1\WidgetTypeInterface`.
- Every widget method receives `WidgetContextInterface $ctx` as its first
  argument.
- Do not extend `AbstractWidgetType` and do not implement older widget
  interfaces.

This keeps custom widgets dependent on
`hyva-themes/commerce-module-admin-dashboard-api` rather than the full
dashboard runtime.

Useful official docs:

- PHP implementation: https://docs.hyva.io/hyva-commerce/features/admin-dashboard/devdocs/widget-types/php.html
- XML configuration: https://docs.hyva.io/hyva-commerce/features/admin-dashboard/devdocs/widget-types/xml.html
- Configurable inputs: https://docs.hyva.io/hyva-commerce/features/admin-dashboard/devdocs/widget-types/configurable-inputs.html
- Available widget types: https://docs.hyva.io/hyva-commerce/features/admin-dashboard/devdocs/widget-types/available-types.html

## Widget Type Vs Instance

- A **widget type** is the reusable definition: one XML `<widget>` entry plus
  one PHP class implementing the relevant widget type interface.
- A **widget instance** is what an admin places on a dashboard: a widget type
  plus saved configuration/display values.

Creating a widget is two steps: register it in XML, then implement the PHP
behavior.

## XML Registration

Create `etc/adminhtml/hyva_dashboard_widget.xml` and use the API-package
schema:

```xml
xsi:noNamespaceSchemaLocation="urn:magento:module:Hyva_AdminDashboardApi:etc/adminhtml/hyva_dashboard_widget.xsd"
```

Minimal widget:

```xml
<?xml version="1.0"?>
<config xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:noNamespaceSchemaLocation="urn:magento:module:Hyva_AdminDashboardApi:etc/adminhtml/hyva_dashboard_widget.xsd">
    <widget id="my_widget">
        <class>Vendor\Module\Model\Widget\MyWidget</class>
        <display_type>text</display_type>
    </widget>
</config>
```

Custom template widget:

```xml
<widget id="my_widget">
    <title>My Widget</title>
    <class>Vendor\Module\Model\Widget\MyWidget</class>
    <category>operations</category>
    <tags>orders,operations</tags>
    <display_type>template</display_type>
    <template>Vendor_Module::widget/my-widget.phtml</template>
    <icon>chart-spline</icon>
    <min_height>2</min_height>
    <min_width>2</min_width>
    <trailing_action>
        <label>View all</label>
        <route>sales/order/index</route>
        <target>_self</target>
    </trailing_action>
</widget>
```

XML keys:

| Key | Required | Notes |
|---|---|---|
| `id` attribute | yes | Unique non-empty alphanumeric value; hyphen, underscore, and period are allowed. |
| `disabled` attribute | no | Defaults to `false`; disabled widgets cannot be created, edited, deleted, or rendered. |
| `class` | yes | PHP class implementing `Hyva\AdminDashboardApi\Api\V1\WidgetTypeInterface`. |
| `display_type` | yes | Template key such as `text`, `table`, `bar_chart`, `line_chart`, `pie_chart`, `date-interval-table`, or `template`. |
| `template` | required for `display_type=template` | Magento template notation, e.g. `Vendor_Module::widget/my-widget.phtml`. |
| `acl` | no | Magento ACL resource; defaults to `Magento_Backend::admin`. |
| `cache_lifetime` | no | Seconds; default is `86400`. |
| `category` | no | Groups widgets in the Add Widget modal; uncategorized widgets appear under `Other`. |
| `full_screen` | no | Enables a full-screen widget instance menu action. |
| `icon` | no | Lucide icon name available to `Hyva\Theme\ViewModel\LucideIcons`. |
| `min_height` / `min_width` | no | Dashboard grid minimum rows/columns; default is `1`. |
| `tags` | no | Comma-separated search keywords. |
| `title` | no | Defaults to the formatted widget `id`. |
| `trailing_action` | no | Footer link data: `label`, `route`, optional `target` (`_self` or `_blank`). |

For non-template display types, the display type must be mapped by the
dashboard runtime converter configuration. Official built-ins include
`table`, `bar_chart`, `line_chart`, `pie_chart`, and several first-party
template widgets.

## PHP Implementation

Implement `Hyva\AdminDashboardApi\Api\V1\WidgetTypeInterface`.

```php
<?php
declare(strict_types=1);

namespace Vendor\Module\Model\Widget;

use Hyva\AdminDashboardApi\Api\V1\WidgetContextInterface;
use Hyva\AdminDashboardApi\Api\V1\WidgetInstanceInterface;
use Hyva\AdminDashboardApi\Api\V1\WidgetTypeInterface;
use Magento\Framework\Phrase;

class MyWidget implements WidgetTypeInterface
{
    public function getDisplayData(WidgetContextInterface $ctx, WidgetInstanceInterface $widgetInstance): mixed
    {
        return [];
    }

    public function getTitle(WidgetContextInterface $ctx, ?WidgetInstanceInterface $widgetInstance): Phrase
    {
        return $ctx->getTitle();
    }

    public function getConfigurableProperties(WidgetContextInterface $ctx): array
    {
        return $ctx->getConfigurableProperties();
    }

    public function getDisplayProperties(WidgetContextInterface $ctx): array
    {
        return $ctx->getDisplayProperties();
    }

    public function getTrailingAction(WidgetContextInterface $ctx, ?WidgetInstanceInterface $widgetInstance): array
    {
        return $ctx->getTrailingAction();
    }

    public function isAllowed(WidgetContextInterface $ctx, ?WidgetInstanceInterface $widgetInstance): bool
    {
        return $ctx->isAllowed($widgetInstance);
    }

    public function beforeSave(WidgetContextInterface $ctx, WidgetInstanceInterface $widgetInstance): WidgetInstanceInterface
    {
        return $widgetInstance;
    }

    public function afterSave(WidgetContextInterface $ctx, WidgetInstanceInterface $widgetInstance): WidgetInstanceInterface
    {
        return $widgetInstance;
    }
}
```

With this API, read defaults from `$ctx` and merge only your own additions.
`getTitle()` receives `null` before the widget has been placed, so fall back to
`$ctx->getTitle()` when deriving a title from instance configuration.

## Properties

`getConfigurableProperties()` returns inputs that affect data or behavior,
such as filters, URLs, statuses, or date ranges.

`getDisplayProperties()` returns inputs that affect rendering, such as chart
scale, interval, or display options.

Shape:

```php
[
    'limit' => [
        'label' => __('Number of Items'),
        'input' => [
            'type' => 'text',
            'subtype' => 'number',
            'attributes' => ['value' => 5, 'min' => 1, 'max' => 20, 'required' => true],
        ],
    ],
]
```

Common input types include `text`, `date`, `select`, `toggle`, and `scope`.
Conditionally show a field with `depends`, keyed by the other field's form
name:

```php
'target_url' => [
    'label' => __('URL'),
    'input' => [
        'type' => 'text',
        'subtype' => 'url',
        'attributes' => ['required' => true],
        'depends' => ['configurable_properties[url_type]' => 1],
    ],
],
```

Read saved values from the widget instance. Use constants from
`Hyva\AdminDashboardApi\Api\ConfigurationKeys`.

## Display Data

`getDisplayData()` returns the computed value rendered by the widget. The
required shape depends on `display_type` or the custom template.

For the built-in `table` display type:

```php
return [
    'headings' => ['Name', 'Value'],
    'rows' => [
        ['href' => 'https://example.test/', 'values' => ['Foo', 'Bar']],
        ['values' => ['Baz', 'Qux']],
    ],
    'footer' => ['Total', '2'],
    'caption' => 'Example Table',
];
```

Top-level table keys are optional. A row `href` makes the row clickable.

For chart display types, inspect the installed templates for the exact shape
expected by `bar-chart.phtml`, `line-chart.phtml`, or `pie-chart.phtml`.
Marker interfaces live under `Hyva\AdminDashboardApi\Api\V1\ChartType\*`.

## Permissions And Save Hooks

Use XML `acl` for normal access control. Add `isAllowed()` only for extra
per-instance rules.

Use `$ctx->isAllowed($widgetInstance)` as the default implementation, then add
extra checks only when the widget needs per-instance rules.

Use `beforeSave()` and `afterSave()` only for widget-instance save behavior.
Both must return a `WidgetInstanceInterface`, normally the same instance.
Prefer `afterSave()` for side effects such as fetching/caching external data;
catch/log failures and avoid breaking dashboard saves for recoverable errors.

## Custom Templates

For `display_type=template`, create the template under
`view/adminhtml/templates/widget/my-widget.phtml`.

The widget instance is passed on the block:

```php
<?php
use Hyva\AdminDashboardApi\Api\V1\WidgetInstanceInterface;

/** @var WidgetInstanceInterface|null $widgetInstance */
$widgetInstance = $block->getData('widget_instance');

if (!$widgetInstance || !($data = $widgetInstance->getDisplayData())) {
    return;
}
?>
```

Escape output with `$escaper`.

If the template needs formatting helpers, create a view model implementing
`Magento\Framework\View\Element\Block\ArgumentInterface` and load it with
`$viewModels->require(Vendor\Module\ViewModel\MyWidget::class)`.

## Companion JavaScript

For custom interactivity, prefer a separate adminhtml template registered via
layout XML instead of inline script in the content template.

`view/adminhtml/layout/hyva_dashboard_widget.xml`:

```xml
<page xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
      xsi:noNamespaceSchemaLocation="urn:magento:framework:View/Layout/etc/page_configuration.xsd">
    <body>
        <referenceBlock name="widget-container.after">
            <block name="widget-type.my_widget.js" template="Vendor_Module::js/widget/my-widget.phtml"/>
        </referenceBlock>
    </body>
</page>
```

`view/adminhtml/templates/js/widget/my-widget.phtml`:

```php
<script>
    function myWidget()
    {
        return {
            init() {},
        };
    }

    window.addEventListener('alpine:init', () => Alpine.data('myWidget', myWidget), {once: true});
</script>
<?php isset($hyvaCsp) && $hyvaCsp->registerInlineScript(); ?>
```

In the widget content template:

```html
<div x-data="myWidget"></div>
```

## Verification Checklist

- The module path, namespace, and template aliases use the real
  `Vendor/Module`, `Vendor\Module`, and `Vendor_Module` values.
- XML validates against the API-package schema.
- `class` implements `Hyva\AdminDashboardApi\Api\V1\WidgetTypeInterface`.
- `display_type=template` has a valid `<template>` value.
- Built-in `display_type` values are mapped by the dashboard runtime converter.
- Configurable/display properties render, persist, and conditional `depends`
  rules work.
- `getDisplayData()` returns the shape expected by the selected display type.
- ACL and any `isAllowed()` instance rules are checked with an admin user that
  should not have access.
- Save hooks always return the widget instance and handle recoverable failures
  without throwing.
- Run Magento cache flush/setup steps required by the project, then confirm
  the widget appears in the Admin Dashboard Add Widget modal.
