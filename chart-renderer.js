/**
 * Chart Renderer - Optimized visualization engine for Smart Money Concepts
 * High-performance rendering with Chart.js integration
 */

class ChartRenderer {
    constructor(config) {
        this.config = config;
        this.chart = null;
        this.candleData = [];
        this.zones = [];
        this.annotations = [];
        this.canvas = null;
        this.ctx = null;
        
        // Performance optimization
        this.lastRenderTime = 0;
        this.frameRate = 60;
        this.animationFrame = null;
    }

    async init(canvasId) {
        this.canvas = document.getElementById(canvasId);
        if (!this.canvas) {
            throw new Error(`Canvas element with id '${canvasId}' not found`);
        }

        this.ctx = this.canvas.getContext('2d');
        
        // Initialize Chart.js with optimized configuration
        await this.initChart();
        
        console.log('Chart renderer initialized successfully');
    }

    async initChart() {
        // Register custom candlestick chart type first
        this.registerCandlestickChart();
        
        const chartConfig = {
            type: 'line', // Use line chart as base, we'll handle candlesticks in the plugin
            data: {
                datasets: [{
                    label: 'Price',
                    data: [],
                    borderColor: '#007BFF',
                    backgroundColor: 'transparent',
                    fill: false,
                    pointRadius: 0,
                    pointHoverRadius: 0
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                animation: {
                    duration: this.config.get('enableOptimizations') ? 200 : 750
                },
                interaction: {
                    intersect: false,
                    mode: 'index'
                },
                scales: {
                    x: {
                        type: 'time',
                        time: {
                            unit: 'hour',
                            displayFormats: {
                                hour: 'MMM dd, HH:mm'
                            }
                        },
                        grid: {
                            color: 'rgba(255, 255, 255, 0.1)'
                        },
                        ticks: {
                            color: '#8E9AAF',
                            maxTicksLimit: 10
                        }
                    },
                    y: {
                        position: 'right',
                        grid: {
                            color: 'rgba(255, 255, 255, 0.1)'
                        },
                        ticks: {
                            color: '#8E9AAF',
                            callback: function(value) {
                                return value.toFixed(5);
                            }
                        }
                    }
                },
                plugins: {
                    legend: {
                        display: false
                    },
                    tooltip: {
                        enabled: true,
                        mode: 'index',
                        intersect: false,
                        backgroundColor: 'rgba(0, 0, 0, 0.8)',
                        titleColor: '#FFFFFF',
                        bodyColor: '#FFFFFF',
                        borderColor: '#007BFF',
                        borderWidth: 1,
                        callbacks: {
                            title: function(context) {
                                const date = new Date(context[0].parsed.x);
                                return date.toLocaleString();
                            },
                            label: function(context) {
                                const data = context.raw;
                                if (data && typeof data === 'object' && 'o' in data) {
                                    return [
                                        `Open: ${data.o.toFixed(5)}`,
                                        `High: ${data.h.toFixed(5)}`,
                                        `Low: ${data.l.toFixed(5)}`,
                                        `Close: ${data.c.toFixed(5)}`
                                    ];
                                }
                                return `Value: ${context.parsed.y.toFixed(5)}`;
                            }
                        }
                    }
                }
            },
            // Custom plugins for candlesticks and SMC overlays
            plugins: [this.createCandlestickPlugin(), this.createSMCPlugin()]
        };

        this.chart = new Chart(this.ctx, chartConfig);
    }

    registerCandlestickChart() {
        // This method is kept for compatibility but actual candlestick rendering is handled by plugin
        console.log('Candlestick chart registration completed');
    }

    createCandlestickPlugin() {
        return {
            id: 'candlestickRenderer',
            afterDatasetsDraw: (chart) => {
                this.drawCandlesticks(chart);
            }
        };
    }

    drawCandlesticks(chart) {
        if (!chart || !chart.ctx || !this.candleData) return;

        const ctx = chart.ctx;
        const { chartArea } = chart;
        
        if (!chartArea) return;

        ctx.save();
        
        // Calculate candle width based on visible data points
        const visibleData = this.candleData;
        if (visibleData.length === 0) return;

        const candleWidth = Math.max(2, (chartArea.right - chartArea.left) / visibleData.length * 0.8);
        
        visibleData.forEach((candle, index) => {
            if (!candle) return;
            
            const x = this.getPixelForTime(chart, candle.time);
            const yHigh = this.getPixelForPrice(chart, candle.high);
            const yLow = this.getPixelForPrice(chart, candle.low);
            const yOpen = this.getPixelForPrice(chart, candle.open);
            const yClose = this.getPixelForPrice(chart, candle.close);
            
            // Skip if candle is outside visible area
            if (x < chartArea.left || x > chartArea.right) return;
            
            const isUp = candle.close >= candle.open;
            const color = isUp ? '#00FF00' : '#FF0000';
            const borderColor = isUp ? '#008000' : '#800000';
            
            // Draw wick (high-low line)
            ctx.strokeStyle = borderColor;
            ctx.lineWidth = 1;
            ctx.beginPath();
            ctx.moveTo(x, yHigh);
            ctx.lineTo(x, yLow);
            ctx.stroke();
            
            // Draw candle body
            const bodyTop = Math.min(yOpen, yClose);
            const bodyBottom = Math.max(yOpen, yClose);
            const bodyHeight = bodyBottom - bodyTop;
            
            if (bodyHeight > 0) {
                ctx.fillStyle = color;
                ctx.fillRect(x - candleWidth/2, bodyTop, candleWidth, bodyHeight);
                
                ctx.strokeStyle = borderColor;
                ctx.lineWidth = 1;
                ctx.strokeRect(x - candleWidth/2, bodyTop, candleWidth, bodyHeight);
            } else {
                // Doji - draw horizontal line
                ctx.strokeStyle = borderColor;
                ctx.lineWidth = 2;
                ctx.beginPath();
                ctx.moveTo(x - candleWidth/2, yOpen);
                ctx.lineTo(x + candleWidth/2, yOpen);
                ctx.stroke();
            }
        });
        
        ctx.restore();
    }

    createSMCPlugin() {
        return {
            id: 'smcOverlay',
            afterDatasetsDraw: (chart) => {
                this.drawSMCOverlays(chart);
            }
        };
    }

    async renderChart(processedData) {
        if (!this.chart) {
            throw new Error('Chart not initialized');
        }

        try {
            // Store data for overlay rendering
            this.candleData = processedData.candleData;
            this.zones = processedData.zones || [];
            this.annotations = processedData.annotations || [];

            // Convert candlestick data for Chart.js
            const chartData = this.convertCandlestickData(processedData.candleData);
            
            // Update chart data
            this.chart.data.datasets[0].data = chartData;
            
            // Update chart with optimized rendering
            if (this.config.get('enableOptimizations')) {
                this.chart.update('none'); // No animation for better performance
            } else {
                this.chart.update();
            }

        } catch (error) {
            console.error('Failed to render chart:', error);
            throw error;
        }
    }

    convertCandlestickData(candleData) {
        return candleData.map(candle => ({
            x: candle.time,
            o: candle.open,
            h: candle.high,
            l: candle.low,
            c: candle.close
        }));
    }

    drawSMCOverlays(chart) {
        if (!chart || !chart.ctx) return;

        const ctx = chart.ctx;
        const { chartArea } = chart;
        
        if (!chartArea) return;

        // Save context
        ctx.save();

        // Draw zones (Order Blocks and Fair Value Gaps)
        this.drawZones(ctx, chart);

        // Draw annotations (Liquidity Sweeps and Structure Breaks)
        this.drawAnnotations(ctx, chart);

        // Restore context
        ctx.restore();
    }

    drawZones(ctx, chart) {
        if (!this.config.get('drawOrderBlocks') && !this.config.get('drawFairValueGaps')) {
            return;
        }

        this.zones.forEach(zone => {
            if (!this.shouldDrawZone(zone)) return;

            const x1 = this.getPixelForTime(chart, zone.timeStart);
            const x2 = this.getPixelForTime(chart, zone.timeEnd || zone.timeStart + 3600000);
            const y1 = this.getPixelForPrice(chart, zone.high);
            const y2 = this.getPixelForPrice(chart, zone.low);

            // Skip if zone is outside visible area
            if (x2 < chart.chartArea.left || x1 > chart.chartArea.right) return;

            this.drawZone(ctx, chart, {
                x1: Math.max(x1, chart.chartArea.left),
                x2: Math.min(x2, chart.chartArea.right),
                y1: y1,
                y2: y2,
                zone: zone
            });
        });
    }

    shouldDrawZone(zone) {
        if (zone.type === 'orderBlock' && !this.config.get('drawOrderBlocks')) {
            return false;
        }
        
        if (zone.type === 'fairValueGap' && !this.config.get('drawFairValueGaps')) {
            return false;
        }

        if (zone.status === 'mitigated') {
            if (zone.type === 'orderBlock' && !this.config.get('obShowMitigated')) {
                return false;
            }
            if (zone.type === 'fairValueGap' && !this.config.get('fvgShowMitigated')) {
                return false;
            }
        }

        return true;
    }

    drawZone(ctx, chart, params) {
        const { x1, x2, y1, y2, zone } = params;
        const isMitigated = zone.status === 'mitigated';
        
        // Get colors based on zone type and status
        const colors = this.getZoneColors(zone, isMitigated);
        
        // Draw fill
        if (this.shouldFillZone(zone, isMitigated)) {
            ctx.fillStyle = colors.fill;
            ctx.globalAlpha = isMitigated ? 0.3 : 0.6;
            ctx.fillRect(x1, y1, x2 - x1, y2 - y1);
        }

        // Draw border
        ctx.globalAlpha = isMitigated ? 0.5 : 1.0;
        ctx.strokeStyle = colors.border;
        ctx.lineWidth = this.getZoneLineWidth(zone, isMitigated);
        ctx.setLineDash(this.getZoneLineDash(zone, isMitigated));
        
        ctx.beginPath();
        ctx.rect(x1, y1, x2 - x1, y2 - y1);
        ctx.stroke();
        
        // Reset line dash
        ctx.setLineDash([]);

        // Draw label if enabled
        if (this.shouldShowZoneLabel(zone)) {
            this.drawZoneLabel(ctx, x1, y1, zone);
        }

        // Reset alpha
        ctx.globalAlpha = 1.0;
    }

    getZoneColors(zone, isMitigated) {
        if (isMitigated) {
            return {
                fill: zone.type === 'orderBlock' 
                    ? this.config.get('mitigatedOBColor') || '#808080'
                    : this.config.get('mitigatedFVGColor') || '#C0C0C0',
                border: zone.type === 'orderBlock'
                    ? this.config.get('mitigatedOBBorderColor') || '#696969'
                    : this.config.get('mitigatedFVGBorderColor') || '#C0C0C0'
            };
        }

        if (zone.direction === 'bullish') {
            return {
                fill: zone.type === 'orderBlock'
                    ? this.config.get('bullishOBColor') || '#00BFFF'
                    : this.config.get('bullishFVGColor') || '#87CEEB',
                border: zone.type === 'orderBlock'
                    ? this.config.get('bullishOBBorderColor') || '#0000FF'
                    : this.config.get('bullishFVGBorderColor') || '#6495ED'
            };
        } else {
            return {
                fill: zone.type === 'orderBlock'
                    ? this.config.get('bearishOBColor') || '#F08080'
                    : this.config.get('bearishFVGColor') || '#FFC0CB',
                border: zone.type === 'orderBlock'
                    ? this.config.get('bearishOBBorderColor') || '#FF0000'
                    : this.config.get('bearishFVGBorderColor') || '#FF69B4'
            };
        }
    }

    shouldFillZone(zone, isMitigated) {
        if (isMitigated) {
            return zone.type === 'orderBlock' 
                ? this.config.get('mitigatedOBFill')
                : this.config.get('mitigatedFVGFill');
        }
        
        return zone.type === 'orderBlock'
            ? this.config.get('obFill')
            : this.config.get('fvgFill');
    }

    getZoneLineWidth(zone, isMitigated) {
        if (isMitigated) {
            return zone.type === 'orderBlock'
                ? this.config.get('mitigatedOBWidth') || 1
                : this.config.get('mitigatedFVGWidth') || 1;
        }
        
        return zone.type === 'orderBlock'
            ? this.config.get('obWidth') || 1
            : this.config.get('fvgWidth') || 1;
    }

    getZoneLineDash(zone, isMitigated) {
        if (isMitigated) {
            const style = zone.type === 'orderBlock'
                ? this.config.get('mitigatedOBStyle')
                : this.config.get('mitigatedFVGStyle');
            return this.getLineDashFromStyle(style);
        }
        
        const style = zone.type === 'orderBlock'
            ? this.config.get('obStyle')
            : this.config.get('fvgStyle');
        return this.getLineDashFromStyle(style);
    }

    getLineDashFromStyle(style) {
        switch (style) {
            case 'STYLE_DOT': return [2, 2];
            case 'STYLE_DASH': return [5, 5];
            case 'STYLE_DASHDOT': return [5, 2, 2, 2];
            case 'STYLE_DASHDOTDOT': return [5, 2, 2, 2, 2, 2];
            default: return [];
        }
    }

    shouldShowZoneLabel(zone) {
        return zone.type === 'orderBlock' 
            ? this.config.get('obShowLabels')
            : this.config.get('fvgShowLabels');
    }

    drawZoneLabel(ctx, x, y, zone) {
        const label = this.getZoneLabel(zone);
        
        ctx.font = '10px Arial';
        ctx.fillStyle = zone.direction === 'bullish' ? '#008000' : '#FF0000';
        ctx.textAlign = 'left';
        ctx.textBaseline = 'top';
        
        // Draw background
        const metrics = ctx.measureText(label);
        ctx.fillStyle = 'rgba(255, 255, 255, 0.8)';
        ctx.fillRect(x, y - 2, metrics.width + 4, 14);
        
        // Draw text
        ctx.fillStyle = zone.direction === 'bullish' ? '#008000' : '#FF0000';
        ctx.fillText(label, x + 2, y);
    }

    getZoneLabel(zone) {
        const direction = zone.direction.charAt(0).toUpperCase() + zone.direction.slice(1);
        const type = zone.type === 'orderBlock' ? 'OB' : 'FVG';
        return `${direction} ${type}`;
    }

    drawAnnotations(ctx, chart) {
        this.annotations.forEach(annotation => {
            if (!this.shouldDrawAnnotation(annotation)) return;

            if (annotation.type === 'liquiditySweep') {
                this.drawLiquiditySweep(ctx, chart, annotation);
            } else if (annotation.type === 'structureBreak') {
                this.drawStructureBreak(ctx, chart, annotation);
            }
        });
    }

    shouldDrawAnnotation(annotation) {
        if (annotation.type === 'liquiditySweep' && !this.config.get('drawLiquiditySweeps')) {
            return false;
        }
        
        if (annotation.type === 'structureBreak' && !this.config.get('drawStructure')) {
            return false;
        }

        return true;
    }

    drawLiquiditySweep(ctx, chart, sweep) {
        const x = this.getPixelForTime(chart, sweep.time);
        const y = this.getPixelForPrice(chart, sweep.price);

        // Skip if outside visible area
        if (x < chart.chartArea.left || x > chart.chartArea.right) return;

        const color = sweep.direction === 'bullish' 
            ? this.config.get('bullishLSColor') || '#32CD32'
            : this.config.get('bearishLSColor') || '#FF4500';

        // Draw arrow
        this.drawArrow(ctx, x, y, sweep.direction, color);
    }

    drawArrow(ctx, x, y, direction, color) {
        const size = 8;
        
        ctx.fillStyle = color;
        ctx.strokeStyle = color;
        ctx.lineWidth = 2;
        
        ctx.beginPath();
        if (direction === 'bullish') {
            // Up arrow
            ctx.moveTo(x, y - size);
            ctx.lineTo(x - size, y + size);
            ctx.lineTo(x + size, y + size);
        } else {
            // Down arrow
            ctx.moveTo(x, y + size);
            ctx.lineTo(x - size, y - size);
            ctx.lineTo(x + size, y - size);
        }
        ctx.closePath();
        ctx.fill();
    }

    drawStructureBreak(ctx, chart, structure) {
        const x = this.getPixelForTime(chart, structure.time);
        const y = this.getPixelForPrice(chart, structure.price);

        // Skip if outside visible area
        if (x < chart.chartArea.left || x > chart.chartArea.right) return;

        const color = structure.structureType === 'BOS'
            ? this.config.get('bosColor') || '#00FF00'
            : this.config.get('chochColor') || '#FF00FF';

        // Draw line
        ctx.strokeStyle = color;
        ctx.lineWidth = this.config.get('structureLineWidth') || 2;
        ctx.setLineDash(this.getLineDashFromStyle(this.config.get('structureLineStyle')));
        
        ctx.beginPath();
        ctx.moveTo(chart.chartArea.left, y);
        ctx.lineTo(chart.chartArea.right, y);
        ctx.stroke();
        
        ctx.setLineDash([]);

        // Draw label if enabled
        if (this.config.get('structureShowLabels')) {
            this.drawStructureLabel(ctx, x, y, structure);
        }
    }

    drawStructureLabel(ctx, x, y, structure) {
        const label = `${structure.structureType} ${structure.direction}`;
        
        ctx.font = '10px Arial';
        ctx.fillStyle = structure.structureType === 'BOS' ? '#00FF00' : '#FF00FF';
        ctx.textAlign = 'center';
        ctx.textBaseline = 'bottom';
        
        // Draw background
        const metrics = ctx.measureText(label);
        ctx.fillStyle = 'rgba(0, 0, 0, 0.7)';
        ctx.fillRect(x - metrics.width/2 - 2, y - 14, metrics.width + 4, 12);
        
        // Draw text
        ctx.fillStyle = structure.structureType === 'BOS' ? '#00FF00' : '#FF00FF';
        ctx.fillText(label, x, y - 2);
    }

    getPixelForTime(chart, time) {
        const scale = chart.scales.x;
        return scale.getPixelForValue(time);
    }

    getPixelForPrice(chart, price) {
        const scale = chart.scales.y;
        return scale.getPixelForValue(price);
    }

    updateVisualStyles() {
        if (this.chart) {
            this.chart.update('none');
        }
    }

    getCurrentData() {
        return this.candleData;
    }

    handleResize() {
        if (this.chart) {
            this.chart.resize();
        }
    }

    destroy() {
        if (this.chart) {
            this.chart.destroy();
            this.chart = null;
        }
    }
}
