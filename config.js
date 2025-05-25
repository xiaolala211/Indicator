/**
 * SMC Configuration Manager
 * Handles all configuration settings with validation and persistence
 */

class SMCConfig {
    constructor() {
        this.defaultConfig = {
            // General Settings
            maxBarsToCalculate: 2000,
            deleteObjectsOlderThan: 500,
            objectPrefix: 'SMC_V2_',

            // Order Blocks
            drawOrderBlocks: true,
            obLookbackPeriod: 50,
            minMoveAfterOB: 1.0,
            minImpulseCandles: 1,
            obCheckDisplacement: true,
            obShowMitigated: true,
            obExtendBars: 50,
            obShowLabels: true,

            // OB Visuals - Unmitigated
            bullishOBColor: '#00BFFF',
            bearishOBColor: '#F08080',
            bullishOBBorderColor: '#0000FF',
            bearishOBBorderColor: '#FF0000',
            obStyle: 'STYLE_SOLID',
            obWidth: 1,
            obFill: true,

            // OB Visuals - Mitigated
            mitigatedOBColor: '#808080',
            mitigatedOBBorderColor: '#696969',
            mitigatedOBStyle: 'STYLE_DOT',
            mitigatedOBWidth: 1,
            mitigatedOBFill: false,

            // Fair Value Gaps
            drawFairValueGaps: true,
            fvgLookbackPeriod: 50,
            minFVGSizePoints: 10,
            fvgShowMitigated: true,
            fvgMitigationLevel: 0.5,
            fvgExtendBars: 50,
            fvgShowLabels: true,

            // FVG Visuals - Unmitigated
            bullishFVGColor: '#87CEEB',
            bearishFVGColor: '#FFC0CB',
            bullishFVGBorderColor: '#6495ED',
            bearishFVGBorderColor: '#FF69B4',
            fvgStyle: 'STYLE_SOLID',
            fvgWidth: 1,
            fvgFill: true,

            // FVG Visuals - Mitigated
            mitigatedFVGColor: '#D3D3D3',
            mitigatedFVGBorderColor: '#C0C0C0',
            mitigatedFVGStyle: 'STYLE_DOT',
            mitigatedFVGWidth: 1,
            mitigatedFVGFill: false,

            // Liquidity & Structure
            drawLiquiditySweeps: true,
            sweepMinSpikePoints: 5,
            sweepCloseBackCandles: 1,
            drawStructure: true,
            swingLookback: 15,
            structuralSwingMinBars: 3,
            structureRequiresSweep: true,

            // LS & Structure Visuals
            bullishLSColor: '#32CD32',
            bearishLSColor: '#FF4500',
            arrowBullishSweepCode: 241,
            arrowBearishSweepCode: 242,
            bosColor: '#00FF00',
            chochColor: '#FF00FF',
            structureLineStyle: 'STYLE_DASHDOT',
            structureLineWidth: 1,
            structureShowLabels: true,

            // Alerts
            enableAlerts: false,
            alertOnOB: true,
            alertOnFVG: true,
            alertOnLS: true,
            alertOnStructure: true,
            alertOnlyUnmitigated: true,
            alertType: 'ALERT_MT5',
            alertMaxPerBar: 1,

            // Dashboard
            showDashboard: true,
            dashboardCorner: 'CORNER_TOP_LEFT',
            dashboardXOffset: 10,
            dashboardYOffset: 20,
            dashboardTextColor: '#FFFFFF',
            dashboardFontSize: 8,
            dashboardBgColor: '#000000',
            dashboardUpdateFreqSecs: 5,

            // Performance
            updateFrequency: 1000,
            enableOptimizations: true
        };

        this.config = { ...this.defaultConfig };
        this.validators = this.createValidators();
        
        // Load saved configuration
        this.load();
    }

    createValidators() {
        return {
            maxBarsToCalculate: (value) => {
                const num = parseInt(value);
                return !isNaN(num) && num >= 100 && num <= 10000;
            },
            deleteObjectsOlderThan: (value) => {
                const num = parseInt(value);
                return !isNaN(num) && num >= 0 && num <= 5000;
            },
            obLookbackPeriod: (value) => {
                const num = parseInt(value);
                return !isNaN(num) && num >= 5 && num <= 500;
            },
            minMoveAfterOB: (value) => {
                const num = parseFloat(value);
                return !isNaN(num) && num >= 0.1 && num <= 10.0;
            },
            minImpulseCandles: (value) => {
                const num = parseInt(value);
                return !isNaN(num) && num >= 1 && num <= 10;
            },
            fvgLookbackPeriod: (value) => {
                const num = parseInt(value);
                return !isNaN(num) && num >= 5 && num <= 500;
            },
            minFVGSizePoints: (value) => {
                const num = parseInt(value);
                return !isNaN(num) && num >= 1 && num <= 1000;
            },
            fvgMitigationLevel: (value) => {
                const num = parseFloat(value);
                return !isNaN(num) && num >= 0.1 && num <= 1.0;
            },
            sweepMinSpikePoints: (value) => {
                const num = parseInt(value);
                return !isNaN(num) && num >= 1 && num <= 100;
            },
            swingLookback: (value) => {
                const num = parseInt(value);
                return !isNaN(num) && num >= 3 && num <= 100;
            },
            structuralSwingMinBars: (value) => {
                const num = parseInt(value);
                return !isNaN(num) && num >= 1 && num <= 20;
            },
            updateFrequency: (value) => {
                const num = parseInt(value);
                return !isNaN(num) && num >= 100 && num <= 10000;
            },
            // Color validators
            bullishOBColor: (value) => this.isValidColor(value),
            bearishOBColor: (value) => this.isValidColor(value),
            bullishOBBorderColor: (value) => this.isValidColor(value),
            bearishOBBorderColor: (value) => this.isValidColor(value),
            bullishFVGColor: (value) => this.isValidColor(value),
            bearishFVGColor: (value) => this.isValidColor(value),
            bullishFVGBorderColor: (value) => this.isValidColor(value),
            bearishFVGBorderColor: (value) => this.isValidColor(value),
            bullishLSColor: (value) => this.isValidColor(value),
            bearishLSColor: (value) => this.isValidColor(value),
            bosColor: (value) => this.isValidColor(value),
            chochColor: (value) => this.isValidColor(value),
            mitigatedOBColor: (value) => this.isValidColor(value),
            mitigatedOBBorderColor: (value) => this.isValidColor(value),
            mitigatedFVGColor: (value) => this.isValidColor(value),
            mitigatedFVGBorderColor: (value) => this.isValidColor(value),
            dashboardTextColor: (value) => this.isValidColor(value),
            dashboardBgColor: (value) => this.isValidColor(value)
        };
    }

    isValidColor(value) {
        if (typeof value !== 'string') return false;
        
        // Check hex color format
        if (/^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$/.test(value)) {
            return true;
        }
        
        // Check CSS color names and rgb/rgba formats
        const div = document.createElement('div');
        div.style.color = value;
        return div.style.color !== '';
    }

    get(key) {
        return this.config[key];
    }

    set(key, value) {
        if (this.validate(key, value)) {
            this.config[key] = value;
            this.save();
            return true;
        }
        return false;
    }

    update(key, value) {
        return this.set(key, value);
    }

    validate(key, value) {
        const validator = this.validators[key];
        if (validator) {
            return validator(value);
        }
        
        // No specific validator, accept value
        return true;
    }

    getValidationError(key, value) {
        if (this.validate(key, value)) {
            return null;
        }

        // Return specific error messages
        switch (key) {
            case 'maxBarsToCalculate':
                return 'Max bars must be between 100 and 10,000';
            case 'deleteObjectsOlderThan':
                return 'Delete older than must be between 0 and 5,000';
            case 'obLookbackPeriod':
            case 'fvgLookbackPeriod':
                return 'Lookback period must be between 5 and 500';
            case 'minMoveAfterOB':
                return 'Min move factor must be between 0.1 and 10.0';
            case 'fvgMitigationLevel':
                return 'Mitigation level must be between 0.1 and 1.0';
            case 'updateFrequency':
                return 'Update frequency must be between 100 and 10,000ms';
            default:
                if (key.includes('Color')) {
                    return 'Invalid color format';
                }
                return 'Invalid value';
        }
    }

    reset() {
        this.config = { ...this.defaultConfig };
        this.save();
    }

    resetToDefaults() {
        this.reset();
    }

    getAll() {
        return { ...this.config };
    }

    setAll(newConfig) {
        const errors = [];
        
        for (const [key, value] of Object.entries(newConfig)) {
            if (this.config.hasOwnProperty(key)) {
                if (!this.validate(key, value)) {
                    errors.push({
                        key: key,
                        value: value,
                        error: this.getValidationError(key, value)
                    });
                }
            }
        }

        if (errors.length > 0) {
            return {
                success: false,
                errors: errors
            };
        }

        // All validations passed
        this.config = { ...this.config, ...newConfig };
        this.save();
        
        return {
            success: true,
            errors: []
        };
    }

    save() {
        try {
            const configString = JSON.stringify(this.config, null, 2);
            localStorage.setItem('smcConfig', configString);
            return true;
        } catch (error) {
            console.error('Failed to save configuration:', error);
            return false;
        }
    }

    load() {
        try {
            const configString = localStorage.getItem('smcConfig');
            if (configString) {
                const savedConfig = JSON.parse(configString);
                
                // Merge with defaults to ensure all keys exist
                this.config = { ...this.defaultConfig, ...savedConfig };
                
                console.log('Configuration loaded from localStorage');
                return true;
            }
        } catch (error) {
            console.error('Failed to load configuration:', error);
            // Fallback to defaults
            this.config = { ...this.defaultConfig };
        }
        return false;
    }

    export() {
        return {
            timestamp: new Date().toISOString(),
            version: '2.0',
            config: this.config
        };
    }

    import(exportedConfig) {
        try {
            if (!exportedConfig || !exportedConfig.config) {
                throw new Error('Invalid configuration format');
            }

            const result = this.setAll(exportedConfig.config);
            
            if (result.success) {
                console.log('Configuration imported successfully');
            } else {
                console.warn('Configuration imported with errors:', result.errors);
            }

            return result;
            
        } catch (error) {
            console.error('Failed to import configuration:', error);
            return {
                success: false,
                errors: [{ error: error.message }]
            };
        }
    }

    // Utility methods for specific configuration groups
    getOrderBlockConfig() {
        return {
            drawOrderBlocks: this.get('drawOrderBlocks'),
            obLookbackPeriod: this.get('obLookbackPeriod'),
            minMoveAfterOB: this.get('minMoveAfterOB'),
            minImpulseCandles: this.get('minImpulseCandles'),
            obCheckDisplacement: this.get('obCheckDisplacement'),
            obShowMitigated: this.get('obShowMitigated'),
            obExtendBars: this.get('obExtendBars'),
            obShowLabels: this.get('obShowLabels')
        };
    }

    getFairValueGapConfig() {
        return {
            drawFairValueGaps: this.get('drawFairValueGaps'),
            fvgLookbackPeriod: this.get('fvgLookbackPeriod'),
            minFVGSizePoints: this.get('minFVGSizePoints'),
            fvgShowMitigated: this.get('fvgShowMitigated'),
            fvgMitigationLevel: this.get('fvgMitigationLevel'),
            fvgExtendBars: this.get('fvgExtendBars'),
            fvgShowLabels: this.get('fvgShowLabels')
        };
    }

    getLiquidityStructureConfig() {
        return {
            drawLiquiditySweeps: this.get('drawLiquiditySweeps'),
            sweepMinSpikePoints: this.get('sweepMinSpikePoints'),
            sweepCloseBackCandles: this.get('sweepCloseBackCandles'),
            drawStructure: this.get('drawStructure'),
            swingLookback: this.get('swingLookback'),
            structuralSwingMinBars: this.get('structuralSwingMinBars'),
            structureRequiresSweep: this.get('structureRequiresSweep')
        };
    }

    getPerformanceConfig() {
        return {
            maxBarsToCalculate: this.get('maxBarsToCalculate'),
            deleteObjectsOlderThan: this.get('deleteObjectsOlderThan'),
            updateFrequency: this.get('updateFrequency'),
            enableOptimizations: this.get('enableOptimizations')
        };
    }

    // Event system for configuration changes
    onChange(callback) {
        if (!this.changeListeners) {
            this.changeListeners = [];
        }
        this.changeListeners.push(callback);
    }

    offChange(callback) {
        if (this.changeListeners) {
            const index = this.changeListeners.indexOf(callback);
            if (index > -1) {
                this.changeListeners.splice(index, 1);
            }
        }
    }

    notifyChange(key, oldValue, newValue) {
        if (this.changeListeners) {
            this.changeListeners.forEach(callback => {
                try {
                    callback(key, newValue, oldValue);
                } catch (error) {
                    console.error('Error in config change listener:', error);
                }
            });
        }
    }

    // Override set method to include change notification
    set(key, value) {
        const oldValue = this.config[key];
        
        if (this.validate(key, value)) {
            this.config[key] = value;
            this.save();
            
            // Notify listeners if value actually changed
            if (oldValue !== value) {
                this.notifyChange(key, oldValue, value);
            }
            
            return true;
        }
        return false;
    }
}
