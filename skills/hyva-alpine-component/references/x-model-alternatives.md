# x-model Alternatives for Other Input Types

Each pattern binds the current state with an attribute binding (`:value`, `:checked`, `:selected` or `x-text`) and updates the property in an event handler method.

Contents: Number Inputs, Textarea, Checkboxes, Checkbox Arrays, Select Elements.

## Number Inputs

Use `hyva.safeParseNumber()` for numeric values:

```javascript
return {
    quantity: 1,
    setQuantity() {
        this.quantity = hyva.safeParseNumber(this.$event.target.value);
    }
}
```

## Textarea

```html
<textarea @input="setComment" x-text="comment"></textarea>
```

```javascript
return {
    comment: '',
    setComment() {
        this.comment = this.$event.target.value;
    }
}
```

## Checkboxes

```html
<input type="checkbox"
       :checked="isSubscribed"
       @change="toggleSubscribed">
```

```javascript
return {
    isSubscribed: false,
    toggleSubscribed() {
        this.isSubscribed = this.$event.target.checked;
    }
}
```

## Checkbox Arrays

```html
<template x-for="option in options" :key="option.id">
    <input type="checkbox"
           :value="option.id"
           :checked="isOptionSelected"
           @change="toggleOption"
           :data-option-id="option.id">
</template>
```

```javascript
return {
    selectedOptions: [],
    isOptionSelected() {
        return this.selectedOptions.includes(this.option.id);
    },
    toggleOption() {
        const optionId = this.$el.dataset.optionId;
        const index = this.selectedOptions.indexOf(optionId);
        if (index === -1) {
            this.selectedOptions.push(optionId);
        } else {
            this.selectedOptions.splice(index, 1);
        }
    }
}
```

## Select Elements

```html
<select @change="setCountry">
    <template x-for="country in countries" :key="country.code">
        <option :value="country.code"
                :selected="isCountrySelected"
                x-text="country.name"></option>
    </template>
</select>
```

```javascript
return {
    selectedCountry: '',
    isCountrySelected() {
        return this.selectedCountry === this.country.code;
    },
    setCountry() {
        this.selectedCountry = this.$event.target.value;
    }
}
```
