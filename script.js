/**
 * SMC Visualizer v2.0 - Main Application Controller
 * Optimized Smart Money Concepts indicator for web browsers
 */

class SMCVisualizer {
    constructor() {
        this.config = new SMCConfig();
        this.engine = new SMCEngine(this.config);
        this.renderer = new ChartRenderer(this.config);
        
        this.isInitialized = false;
        this.updateInterval = null;
        this.performanceMetrics = {
            lastUpdateTime: 0,
            averageUpdateTime: 0,
            updateCount: 0
        };
        
        this.alerts = [];
        this.maxAlerts = 50;
        
        this.init();
    }

    async init() {
        try {
            this.showLoading(true);
            
            // Initialize UI event listeners
            this.initEventListeners();
            
            // Initialize chart
            await this.renderer.init('tradingChart');
            
            // Generate sample data (in real implementation, this would connect to a data feed)
            const sampleData = this.generateSampleData();
            await this.loadChartData(sampleData);
            
            // Start update loop
            this.startUpdateLoop();
            
            this.isInitialized = true;
            this.showLoading(false);
            
            this.showToast('SMC Visualizer initialized successfully', 'success');
            this.updateLastUpdateTime();
            
        } catch (error) {
            console.error('Failed to initialize SMC Visualizer:', error);
            this.showToast('Failed to initialize application', 'error');
            this.showLoading(false);
        }
    }

    initEventListeners() {
        // Panel toggle
        document.getElementById('togglePanel').addEventListener('click', () => {
            this.toggleConfigPanel();
        });

        // Configuration changes
        this.initConfigListeners();

        // Chart controls
        document.getElementById('timeframeSelect').addEventListener('change', (e) => {
            this.changeTimeframe(e.target.value);
        });

        document.getElementById('symbolSelect').addEventListener('change', (e) => {
            this.changeSymbol(e.target.value);
        });

        // Header controls
        document.getElementById('resetBtn').addEventListener('click', () => {
            this.resetChart();
        });

        document.getElementById('exportBtn').addEventListener('click', () => {
            this.exportChart();
        });

        // Stats toggle
        document.getElementById('toggleStats').addEventListener('click', () => {
            this.toggleStats();
        });

        // Alerts
        document.getElementById('clearAlerts').addEventListener('click', () => {
            this.clearAlerts();
        });

        // Keyboard shortcuts
        document.addEventListener('keydown', (e) => {
            this.handleKeyboardShortcuts(e);
        });

        // Window resize
        window.addEventListener('resize', () => {
            this.handleResize();
        });
    }

    initConfigListeners() {
        // General settings
        document.getElementById('maxBarsToCalculate').addEventListener('change', (e) => {
            this.config.update('maxBarsToCalculate', parseInt(e.target.value));
            this.engine.updateConfig(this.config);
        });

        document.getElementById('deleteObjectsOlderThan').addEventListener('change', (e) => {
            this.config.update('deleteObjectsOlderThan', parseInt(e.target.value));
            this.engine.updateConfig(this.config);
        });

        // Order Blocks
        document.getElementById('drawOrderBlocks').addEventListener('change', (e) => {
            this.config.update('drawOrderBlocks', e.target.checked);
            this.updateDisplay();
        });

        document.getElementById('obLookbackPeriod').addEventListener('change', (e) => {
            this.config.update('obLookbackPeriod', parseInt(e.target.value));
            this.recalculateAndUpdate();
        });

        document.getElementById('minMoveAfterOB').addEventListener('change', (e) => {
            this.config.update('minMoveAfterOB', parseFloat(e.target.value));
            this.recalculateAndUpdate();
        });

        document.getElementById('obShowMitigated').addEventListener('change', (e) => {
            this.config.update('obShowMitigated', e.target.checked);
            this.updateDisplay();
        });

        // Colors
        document.getElementById('bullishOBColor').addEventListener('change', (e) => {
            this.config.update('bullishOBColor', e.target.value);
            this.updateDisplay();
        });

        document.getElementById('bearishOBColor').addEventListener('change', (e) => {
            this.config.update('bearishOBColor', e.target.value);
            this.updateDisplay();
        });

        // Fair Value Gaps
        document.getElementById('drawFairValueGaps').addEventListener('change', (e) => {
            this.config.update('drawFairValueGaps', e.target.checked);
            this.updateDisplay();
        });

        document.getElementById('fvgLookbackPeriod').addEventListener('change', (e) => {
            this.config.update('fvgLookbackPeriod', parseInt(e.target.value));
            this.recalculateAndUpdate();
        });

        document.getElementById('minFVGSizePoints').addEventListener('change', (e) => {
            this.config.update('minFVGSizePoints', parseInt(e.target.value));
            this.recalculateAndUpdate();
        });

        document.getElementById('fvgMitigationLevel').addEventListener('input', (e) => {
            const value = parseFloat(e.target.value);
            this.config.update('fvgMitigationLevel', value);
            document.querySelector('.range-value').textContent = `${Math.round(value * 100)}%`;
            this.recalculateAndUpdate();
        });

        document.getElementById('bullishFVGColor').addEventListener('change', (e) => {
            this.config.update('bullishFVGColor', e.target.value);
            this.updateDisplay();
        });

        document.getElementById('bearishFVGColor').addEventListener('change', (e) => {
            this.config.update('bearishFVGColor', e.target.value);
            this.updateDisplay();
        });

        // Liquidity & Structure
        document.getElementById('drawLiquiditySweeps').addEventListener('change', (e) => {
            this.config.update('drawLiquiditySweeps', e.target.checked);
            this.updateDisplay();
        });

        document.getElementById('sweepMinSpikePoints').addEventListener('change', (e) => {
            this.config.update('sweepMinSpikePoints', parseInt(e.target.value));
            this.recalculateAndUpdate();
        });

        document.getElementById('drawStructure').addEventListener('change', (e) => {
            this.config.update('drawStructure', e.target.checked);
            this.updateDisplay();
        });

        document.getElementById('swingLookback').addEventListener('change', (e) => {
            this.config.update('swingLookback', parseInt(e.target.value));
            this.recalculateAndUpdate();
        });

        // Performance
        document.getElementById('updateFrequency').addEventListener('change', (e) => {
            this.config.update('updateFrequency', parseInt(e.target.value));
            this.restartUpdateLoop();
        });

        document.getElementById('enableOptimizations').addEventListener('change', (e) => {
            this.config.update('enableOptimizations', e.target.checked);
            this.engine.updateConfig(this.config);
        });
    }

    async loadChartData(data) {
        try {
            // Process data through SMC engine
            const processedData = await this.engine.processData(data);
            
            // Render chart with SMC overlays
            await this.renderer.renderChart(processedData);
            
            // Update statistics
            this.updateStatistics(processedData);
            
        } catch (error) {
            console.error('Failed to load chart data:', error);
            this.showToast('Failed to load chart data', 'error');
        }
    }

    async recalculateAndUpdate() {
        if (!this.isInitialized) return;
        
        const startTime = performance.now();
        
        try {
            // Re-process current data with new settings
            const currentData = this.renderer.getCurrentData();
            if (currentData) {
                await this.loadChartData(currentData);
            }
            
            // Update performance metrics
            this.updatePerformanceMetrics(performance.now() - startTime);
            
        } catch (error) {
            console.error('Failed to recalculate:', error);
            this.showToast('Failed to recalculate indicators', 'error');
        }
    }

    updateDisplay() {
        if (!this.isInitialized) return;
        
        try {
            // Update visual styles without recalculation
            this.renderer.updateVisualStyles();
            
        } catch (error) {
            console.error('Failed to update display:', error);
        }
    }

    updateStatistics(processedData) {
        if (!processedData) return;
        
        const stats = this.engine.getStatistics();
        
        document.getElementById('statOrderBlocks').textContent = stats.orderBlocks || 0;
        document.getElementById('statFVGs').textContent = stats.fairValueGaps || 0;
        document.getElementById('statSweeps').textContent = stats.liquiditySweeps || 0;
        document.getElementById('statStructure').textContent = stats.structureBreaks || 0;
        document.getElementById('statPerformance').textContent = 
            `${this.performanceMetrics.averageUpdateTime.toFixed(1)}ms`;
    }

    updatePerformanceMetrics(updateTime) {
        this.performanceMetrics.updateCount++;
        this.performanceMetrics.lastUpdateTime = updateTime;
        
        // Calculate running average
        if (this.performanceMetrics.updateCount === 1) {
            this.performanceMetrics.averageUpdateTime = updateTime;
        } else {
            const alpha = 0.1; // Smoothing factor
            this.performanceMetrics.averageUpdateTime = 
                alpha * updateTime + (1 - alpha) * this.performanceMetrics.averageUpdateTime;
        }
    }

    startUpdateLoop() {
        this.stopUpdateLoop();
        
        const updateFrequency = this.config.get('updateFrequency');
        this.updateInterval = setInterval(() => {
            this.performUpdate();
        }, updateFrequency);
    }

    stopUpdateLoop() {
        if (this.updateInterval) {
            clearInterval(this.updateInterval);
            this.updateInterval = null;
        }
    }

    restartUpdateLoop() {
        this.startUpdateLoop();
    }

    async performUpdate() {
        if (!this.isInitialized) return;
        
        const startTime = performance.now();
        
        try {
            // In a real implementation, this would fetch new data
            // For demo purposes, we'll simulate minor updates
            const hasNewData = Math.random() < 0.1; // 10% chance of new data
            
            if (hasNewData) {
                await this.simulateNewData();
            }
            
            // Update timestamp
            this.updateLastUpdateTime();
            
            // Update performance metrics
            this.updatePerformanceMetrics(performance.now() - startTime);
            
        } catch (error) {
            console.error('Update error:', error);
        }
    }

    async simulateNewData() {
        // Simulate adding a new candle
        const currentData = this.renderer.getCurrentData();
        if (currentData && currentData.length > 0) {
            const lastCandle = currentData[currentData.length - 1];
            const newCandle = this.generateNextCandle(lastCandle);
            
            currentData.push(newCandle);
            
            // Process and update
            await this.loadChartData(currentData);
            
            // Check for alerts
            this.checkForAlerts();
        }
    }

    generateNextCandle(lastCandle) {
        const volatility = 0.001; // 0.1% volatility
        const trend = (Math.random() - 0.5) * 0.0005; // Small trend bias
        
        const change = (Math.random() - 0.5) * volatility + trend;
        const open = lastCandle.close;
        const close = open * (1 + change);
        
        const range = Math.abs(change) * (1 + Math.random());
        const high = Math.max(open, close) * (1 + range);
        const low = Math.min(open, close) * (1 - range);
        
        return {
            time: lastCandle.time + 3600000, // Add 1 hour
            open: open,
            high: high,
            low: low,
            close: close,
            volume: Math.floor(Math.random() * 1000) + 500
        };
    }

    checkForAlerts() {
        const newDetections = this.engine.getNewDetections();
        
        newDetections.forEach(detection => {
            this.addAlert(detection);
        });
    }

    addAlert(detection) {
        const alert = {
            id: Date.now() + Math.random(),
            timestamp: new Date(),
            type: detection.type,
            message: this.formatAlertMessage(detection),
            level: this.getAlertLevel(detection.type)
        };
        
        this.alerts.unshift(alert);
        
        // Limit alerts
        if (this.alerts.length > this.maxAlerts) {
            this.alerts = this.alerts.slice(0, this.maxAlerts);
        }
        
        // Show toast notification
        this.showToast(alert.message, alert.level);
        
        // Update alerts panel
        this.updateAlertsPanel();
    }

    formatAlertMessage(detection) {
        const symbol = document.getElementById('symbolSelect').value;
        const timeframe = document.getElementById('timeframeSelect').value;
        
        switch (detection.type) {
            case 'orderBlock':
                return `${detection.direction} Order Block detected on ${symbol} ${timeframe}`;
            case 'fairValueGap':
                return `${detection.direction} Fair Value Gap detected on ${symbol} ${timeframe}`;
            case 'liquiditySweep':
                return `${detection.direction} Liquidity Sweep on ${symbol} ${timeframe}`;
            case 'structureBreak':
                return `${detection.structureType} detected on ${symbol} ${timeframe}`;
            default:
                return `New SMC pattern detected on ${symbol} ${timeframe}`;
        }
    }

    getAlertLevel(type) {
        switch (type) {
            case 'structureBreak':
                return 'warning';
            case 'liquiditySweep':
                return 'error';
            default:
                return 'success';
        }
    }

    updateAlertsPanel() {
        const alertsContent = document.getElementById('alertsContent');
        
        if (this.alerts.length === 0) {
            alertsContent.innerHTML = `
                <div class="no-alerts">
                    <i class="fas fa-bell-slash"></i>
                    <p>No alerts</p>
                </div>
            `;
            return;
        }
        
        const alertsHTML = this.alerts.map(alert => `
            <div class="alert-item ${alert.level}">
                <div class="alert-header">
                    <span class="alert-type">${alert.type}</span>
                    <span class="alert-time">${alert.timestamp.toLocaleTimeString()}</span>
                </div>
                <div class="alert-message">${alert.message}</div>
            </div>
        `).join('');
        
        alertsContent.innerHTML = alertsHTML;
    }

    clearAlerts() {
        this.alerts = [];
        this.updateAlertsPanel();
        this.showToast('Alerts cleared', 'success');
    }

    toggleConfigPanel() {
        const panel = document.getElementById('configPanel');
        panel.classList.toggle('collapsed');
        
        const icon = document.querySelector('#togglePanel i');
        if (panel.classList.contains('collapsed')) {
            icon.className = 'fas fa-chevron-right';
        } else {
            icon.className = 'fas fa-chevron-left';
        }
    }

    toggleStats() {
        const content = document.querySelector('.stats-content');
        const icon = document.querySelector('#toggleStats i');
        
        content.classList.toggle('collapsed');
        
        if (content.classList.contains('collapsed')) {
            icon.className = 'fas fa-chevron-up';
        } else {
            icon.className = 'fas fa-chevron-down';
        }
    }

    async changeTimeframe(timeframe) {
        this.showLoading(true);
        
        try {
            // Update chart title
            const symbol = document.getElementById('symbolSelect').value;
            document.getElementById('chartTitle').textContent = `${symbol} - ${timeframe}`;
            
            // Generate new data for timeframe
            const newData = this.generateSampleData(timeframe);
            await this.loadChartData(newData);
            
            this.showToast(`Switched to ${timeframe} timeframe`, 'success');
            
        } catch (error) {
            console.error('Failed to change timeframe:', error);
            this.showToast('Failed to change timeframe', 'error');
        } finally {
            this.showLoading(false);
        }
    }

    async changeSymbol(symbol) {
        this.showLoading(true);
        
        try {
            // Update chart title
            const timeframe = document.getElementById('timeframeSelect').value;
            document.getElementById('chartTitle').textContent = `${symbol} - ${timeframe}`;
            
            // Generate new data for symbol
            const newData = this.generateSampleData(timeframe, symbol);
            await this.loadChartData(newData);
            
            this.showToast(`Switched to ${symbol}`, 'success');
            
        } catch (error) {
            console.error('Failed to change symbol:', error);
            this.showToast('Failed to change symbol', 'error');
        } finally {
            this.showLoading(false);
        }
    }

    resetChart() {
        if (confirm('Are you sure you want to reset the chart? This will clear all current data and settings.')) {
            // Reset configuration
            this.config.reset();
            
            // Update UI controls
            this.updateUIFromConfig();
            
            // Regenerate data
            const symbol = document.getElementById('symbolSelect').value;
            const timeframe = document.getElementById('timeframeSelect').value;
            const newData = this.generateSampleData(timeframe, symbol);
            this.loadChartData(newData);
            
            // Clear alerts
            this.clearAlerts();
            
            this.showToast('Chart reset successfully', 'success');
        }
    }

    updateUIFromConfig() {
        // Update all form controls to match config
        document.getElementById('maxBarsToCalculate').value = this.config.get('maxBarsToCalculate');
        document.getElementById('deleteObjectsOlderThan').value = this.config.get('deleteObjectsOlderThan');
        document.getElementById('drawOrderBlocks').checked = this.config.get('drawOrderBlocks');
        document.getElementById('obLookbackPeriod').value = this.config.get('obLookbackPeriod');
        // ... update all other controls
    }

    exportChart() {
        try {
            const canvas = document.getElementById('tradingChart');
            const dataURL = canvas.toDataURL('image/png');
            
            const link = document.createElement('a');
            link.download = `smc-chart-${Date.now()}.png`;
            link.href = dataURL;
            link.click();
            
            this.showToast('Chart exported successfully', 'success');
            
        } catch (error) {
            console.error('Failed to export chart:', error);
            this.showToast('Failed to export chart', 'error');
        }
    }

    handleKeyboardShortcuts(e) {
        if (e.ctrlKey || e.metaKey) {
            switch (e.key) {
                case 'r':
                    e.preventDefault();
                    this.resetChart();
                    break;
                case 's':
                    e.preventDefault();
                    this.exportChart();
                    break;
                case '\\':
                    e.preventDefault();
                    this.toggleConfigPanel();
                    break;
            }
        }
    }

    handleResize() {
        // Debounce resize handling
        clearTimeout(this.resizeTimeout);
        this.resizeTimeout = setTimeout(() => {
            if (this.renderer) {
                this.renderer.handleResize();
            }
        }, 250);
    }

    showLoading(show) {
        const overlay = document.getElementById('loadingOverlay');
        if (show) {
            overlay.classList.remove('hidden');
        } else {
            overlay.classList.add('hidden');
        }
    }

    showToast(message, type = 'success', duration = 3000) {
        const toast = document.createElement('div');
        toast.className = `toast ${type}`;
        toast.innerHTML = `
            <div class="toast-content">
                <i class="fas fa-${this.getToastIcon(type)}"></i>
                <span>${message}</span>
            </div>
        `;
        
        const container = document.getElementById('toastContainer');
        container.appendChild(toast);
        
        // Auto remove
        setTimeout(() => {
            toast.style.transform = 'translateX(320px)';
            setTimeout(() => {
                if (toast.parentNode) {
                    toast.parentNode.removeChild(toast);
                }
            }, 300);
        }, duration);
    }

    getToastIcon(type) {
        switch (type) {
            case 'success': return 'check-circle';
            case 'warning': return 'exclamation-triangle';
            case 'error': return 'times-circle';
            default: return 'info-circle';
        }
    }

    updateLastUpdateTime() {
        const now = new Date();
        document.getElementById('lastUpdate').textContent = 
            `Last update: ${now.toLocaleTimeString()}`;
    }

    generateSampleData(timeframe = 'H1', symbol = 'EURUSD') {
        const basePrice = this.getBasePrice(symbol);
        const candles = [];
        const candleCount = 500;
        
        let currentTime = Date.now() - (candleCount * this.getTimeframeMs(timeframe));
        let currentPrice = basePrice;
        
        for (let i = 0; i < candleCount; i++) {
            const volatility = this.getSymbolVolatility(symbol);
            const change = (Math.random() - 0.5) * volatility;
            
            const open = currentPrice;
            const close = open * (1 + change);
            
            const range = Math.abs(change) * (1 + Math.random() * 2);
            const high = Math.max(open, close) * (1 + range);
            const low = Math.min(open, close) * (1 - range);
            
            candles.push({
                time: currentTime,
                open: this.roundPrice(open, symbol),
                high: this.roundPrice(high, symbol),
                low: this.roundPrice(low, symbol),
                close: this.roundPrice(close, symbol),
                volume: Math.floor(Math.random() * 1000) + 500
            });
            
            currentTime += this.getTimeframeMs(timeframe);
            currentPrice = close;
        }
        
        return candles;
    }

    getBasePrice(symbol) {
        const basePrices = {
            'EURUSD': 1.1000,
            'GBPUSD': 1.3000,
            'USDJPY': 110.00,
            'AUDUSD': 0.7500,
            'USDCAD': 1.2500,
            'XAUUSD': 1900.00
        };
        return basePrices[symbol] || 1.0000;
    }

    getSymbolVolatility(symbol) {
        const volatilities = {
            'EURUSD': 0.001,
            'GBPUSD': 0.0015,
            'USDJPY': 0.002,
            'AUDUSD': 0.0012,
            'USDCAD': 0.0008,
            'XAUUSD': 0.01
        };
        return volatilities[symbol] || 0.001;
    }

    getTimeframeMs(timeframe) {
        const timeframes = {
            'M1': 60000,
            'M5': 300000,
            'M15': 900000,
            'M30': 1800000,
            'H1': 3600000,
            'H4': 14400000,
            'D1': 86400000
        };
        return timeframes[timeframe] || 3600000;
    }

    roundPrice(price, symbol) {
        const decimals = {
            'EURUSD': 5,
            'GBPUSD': 5,
            'USDJPY': 3,
            'AUDUSD': 5,
            'USDCAD': 5,
            'XAUUSD': 2
        };
        const decimal = decimals[symbol] || 5;
        return Math.round(price * Math.pow(10, decimal)) / Math.pow(10, decimal);
    }
}

// Initialize application when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
    window.smcApp = new SMCVisualizer();
});
