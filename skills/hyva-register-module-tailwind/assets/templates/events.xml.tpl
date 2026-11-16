<config xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:noNamespaceSchemaLocation="urn:magento:framework:Event/etc/events.xsd"
>
    <event name="hyva_config_generate_before">
        <observer
            name="{{VENDOR}}_{{MODULE}}_Register_Hyva_Config"
            instance="{{VENDOR}}\{{MODULE}}\Observer\RegisterModuleForHyvaConfig"
        />
    </event>
</config>
