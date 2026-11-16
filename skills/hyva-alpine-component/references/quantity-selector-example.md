# Complete Example: Quantity Selector

```php
<?php
declare(strict_types=1);

use Hyva\Theme\ViewModel\HyvaCsp;
use Magento\Framework\Escaper;

/** @var Escaper $escaper */
/** @var HyvaCsp $hyvaCsp */

$productId = (int) $product->getId();
$minQty = 1;
$maxQty = 100;
$defaultQty = 1;
?>
<div x-data="initQtySelector">
    <label for="qty-<?= $productId ?>" class="sr-only">
        <?= $escaper->escapeHtml(__('Quantity')) ?>
    </label>
    <div class="flex items-center">
        <button type="button"
                class="btn"
                @click="decrement"
                :disabled="isMinQty"
                :class="decrementClasses">
            -
        </button>
        <input type="number"
               id="qty-<?= $productId ?>"
               name="qty"
               :value="qty"
               @input="onInput"
               min="<?= $minQty ?>"
               max="<?= $maxQty ?>"
               class="form-input w-16 text-center">
        <button type="button"
                class="btn"
                @click="increment"
                :disabled="isMaxQty"
                :class="incrementClasses">
            +
        </button>
    </div>
</div>
<script>
    function initQtySelector() {
        return {
            qty: <?= (int) $defaultQty ?>,
            minQty: <?= (int) $minQty ?>,
            maxQty: <?= (int) $maxQty ?>,
            productId: '<?= $productId ?>',

            onInput() {
                let value = hyva.safeParseNumber(this.$event.target.value);
                if (value < this.minQty) value = this.minQty;
                if (value > this.maxQty) value = this.maxQty;
                this.qty = value;
                this.$dispatch('update-qty-' + this.productId, this.qty);
            },

            increment() {
                if (this.qty < this.maxQty) {
                    this.qty++;
                    this.$dispatch('update-qty-' + this.productId, this.qty);
                }
            },

            decrement() {
                if (this.qty > this.minQty) {
                    this.qty--;
                    this.$dispatch('update-qty-' + this.productId, this.qty);
                }
            },

            isMinQty() {
                return this.qty <= this.minQty;
            },

            isMaxQty() {
                return this.qty >= this.maxQty;
            },

            decrementClasses() {
                return { 'opacity-50 cursor-not-allowed': this.isMinQty() };
            },

            incrementClasses() {
                return { 'opacity-50 cursor-not-allowed': this.isMaxQty() };
            }
        }
    }
    window.addEventListener('alpine:init', () => Alpine.data('initQtySelector', initQtySelector), {once: true})
</script>
<?php $hyvaCsp->registerInlineScript() ?>
```
