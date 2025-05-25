/**
 * SMC Engine - Smart Money Concepts Detection Logic
 * Optimized algorithms for Order Blocks, Fair Value Gaps, Liquidity Sweeps, and Market Structure
 */

class SMCEngine {
    constructor(config) {
        this.config = config;
        this.zones = [];
        this.structurePoints = [];
        this.newDetections = [];
        this.statistics = {
            orderBlocks: 0,
            fairValueGaps: 0,
            liquiditySweeps: 0,
            structureBreaks: 0
        };
    }

    updateConfig(config) {
        this.config = config;
    }

    async processData(data) {
        if (!data || data.length < 2) {
            return { candleData: data, zones: [], annotations: [] };
        }

        const startTime = performance.now();
        
        // Clear previous detections
        this.newDetections = [];
        
        // Optimize data processing based on configuration
        const maxBars = this.config.get('maxBarsToCalculate');
        const processData = maxBars > 0 ? data.slice(-maxBars) : data;
        
        // Detect patterns
        const detectedZones = [];
        const annotations = [];

        if (this.config.get('drawOrderBlocks')) {
            const orderBlocks = this.detectOrderBlocks(processData);
            detectedZones.push(...orderBlocks);
        }

        if (this.config.get('drawFairValueGaps')) {
            const fairValueGaps = this.detectFairValueGaps(processData);
            detectedZones.push(...fairValueGaps);
        }

        if (this.config.get('drawLiquiditySweeps')) {
            const liquiditySweeps = this.detectLiquiditySweeps(processData);
            annotations.push(...liquiditySweeps);
        }

        if (this.config.get('drawStructure')) {
            const structureBreaks = this.detectStructureBreaks(processData);
            annotations.push(...structureBreaks);
        }

        // Update zones with mitigation status
        this.updateZoneMitigation(detectedZones, processData);

        // Clean old zones if configured
        this.cleanOldZones(detectedZones, processData);

        // Store zones for future reference
        this.zones = detectedZones;

        // Update statistics
        this.updateStatistics();

        const processingTime = performance.now() - startTime;
        console.log(`SMC processing completed in ${processingTime.toFixed(2)}ms`);

        return {
            candleData: data,
            zones: detectedZones,
            annotations: annotations,
            processingTime: processingTime
        };
    }

    detectOrderBlocks(data) {
        const orderBlocks = [];
        const lookback = this.config.get('obLookbackPeriod');
        const minMoveAfterOB = this.config.get('minMoveAfterOB');
        const checkDisplacement = this.config.get('obCheckDisplacement');

        for (let i = lookback; i < data.length - 1; i++) {
            const candle = data[i];
            const nextCandle = data[i + 1];
            
            // Check for bullish order block
            if (this.isBullishOrderBlock(data, i, lookback, minMoveAfterOB, checkDisplacement)) {
                const orderBlock = {
                    type: 'orderBlock',
                    direction: 'bullish',
                    high: candle.high,
                    low: candle.low,
                    timeStart: candle.time,
                    timeEnd: this.calculateExtendTime(candle.time),
                    barIndex: i,
                    status: 'unmitigated',
                    touchCount: 0,
                    created: Date.now()
                };
                
                orderBlocks.push(orderBlock);
                this.newDetections.push(orderBlock);
            }
            
            // Check for bearish order block
            if (this.isBearishOrderBlock(data, i, lookback, minMoveAfterOB, checkDisplacement)) {
                const orderBlock = {
                    type: 'orderBlock',
                    direction: 'bearish',
                    high: candle.high,
                    low: candle.low,
                    timeStart: candle.time,
                    timeEnd: this.calculateExtendTime(candle.time),
                    barIndex: i,
                    status: 'unmitigated',
                    touchCount: 0,
                    created: Date.now()
                };
                
                orderBlocks.push(orderBlock);
                this.newDetections.push(orderBlock);
            }
        }

        return orderBlocks;
    }

    isBullishOrderBlock(data, index, lookback, minMoveAfterOB, checkDisplacement) {
        const candle = data[index];
        
        // Must be a bearish candle (down candle that will be broken)
        if (candle.close >= candle.open) return false;
        
        // Check if there's a significant move up after this candle
        let maxHigh = candle.high;
        let impulseMoveSize = 0;
        let consecutiveUpCandles = 0;
        
        for (let j = index + 1; j < Math.min(index + lookback, data.length); j++) {
            const futureCandle = data[j];
            
            if (futureCandle.close > futureCandle.open) {
                consecutiveUpCandles++;
            }
            
            if (futureCandle.high > maxHigh) {
                maxHigh = futureCandle.high;
                impulseMoveSize = maxHigh - candle.high;
            }
        }
        
        const candleRange = candle.high - candle.low;
        const requiredMove = candleRange * minMoveAfterOB;
        
        // Check minimum impulse move requirement
        if (impulseMoveSize < requiredMove) return false;
        
        // Check displacement requirement
        if (checkDisplacement && maxHigh <= candle.high) return false;
        
        // Check minimum consecutive impulse candles
        const minImpulseCandles = this.config.get('minImpulseCandles') || 1;
        if (consecutiveUpCandles < minImpulseCandles) return false;
        
        return true;
    }

    isBearishOrderBlock(data, index, lookback, minMoveAfterOB, checkDisplacement) {
        const candle = data[index];
        
        // Must be a bullish candle (up candle that will be broken)
        if (candle.close <= candle.open) return false;
        
        // Check if there's a significant move down after this candle
        let minLow = candle.low;
        let impulseMoveSize = 0;
        let consecutiveDownCandles = 0;
        
        for (let j = index + 1; j < Math.min(index + lookback, data.length); j++) {
            const futureCandle = data[j];
            
            if (futureCandle.close < futureCandle.open) {
                consecutiveDownCandles++;
            }
            
            if (futureCandle.low < minLow) {
                minLow = futureCandle.low;
                impulseMoveSize = candle.low - minLow;
            }
        }
        
        const candleRange = candle.high - candle.low;
        const requiredMove = candleRange * minMoveAfterOB;
        
        // Check minimum impulse move requirement
        if (impulseMoveSize < requiredMove) return false;
        
        // Check displacement requirement
        if (checkDisplacement && minLow >= candle.low) return false;
        
        // Check minimum consecutive impulse candles
        const minImpulseCandles = this.config.get('minImpulseCandles') || 1;
        if (consecutiveDownCandles < minImpulseCandles) return false;
        
        return true;
    }

    detectFairValueGaps(data) {
        const fairValueGaps = [];
        const lookback = this.config.get('fvgLookbackPeriod');
        const minSize = this.config.get('minFVGSizePoints');

        for (let i = 2; i < data.length; i++) {
            const candle1 = data[i - 2];
            const candle2 = data[i - 1];
            const candle3 = data[i];
            
            // Check for bullish FVG
            if (this.isBullishFVG(candle1, candle2, candle3, minSize)) {
                const gap = {
                    type: 'fairValueGap',
                    direction: 'bullish',
                    high: candle1.low,
                    low: candle3.high,
                    timeStart: candle2.time,
                    timeEnd: this.calculateExtendTime(candle2.time),
                    barIndex: i - 1,
                    status: 'unmitigated',
                    touchCount: 0,
                    created: Date.now()
                };
                
                fairValueGaps.push(gap);
                this.newDetections.push(gap);
            }
            
            // Check for bearish FVG
            if (this.isBearishFVG(candle1, candle2, candle3, minSize)) {
                const gap = {
                    type: 'fairValueGap',
                    direction: 'bearish',
                    high: candle3.low,
                    low: candle1.high,
                    timeStart: candle2.time,
                    timeEnd: this.calculateExtendTime(candle2.time),
                    barIndex: i - 1,
                    status: 'unmitigated',
                    touchCount: 0,
                    created: Date.now()
                };
                
                fairValueGaps.push(gap);
                this.newDetections.push(gap);
            }
        }

        return fairValueGaps;
    }

    isBullishFVG(candle1, candle2, candle3, minSize) {
        // Bullish FVG: gap between candle1 low and candle3 high
        const gapSize = candle1.low - candle3.high;
        return gapSize > 0 && gapSize >= minSize * 0.0001; // Convert points to price
    }

    isBearishFVG(candle1, candle2, candle3, minSize) {
        // Bearish FVG: gap between candle1 high and candle3 low
        const gapSize = candle3.low - candle1.high;
        return gapSize > 0 && gapSize >= minSize * 0.0001; // Convert points to price
    }

    detectLiquiditySweeps(data) {
        const sweeps = [];
        const minSpikePoints = this.config.get('sweepMinSpikePoints');
        const closeBackCandles = this.config.get('sweepCloseBackCandles') || 1;

        for (let i = 20; i < data.length - closeBackCandles; i++) {
            const candle = data[i];
            
            // Find recent highs and lows
            const recentHigh = this.findRecentHigh(data, i, 20);
            const recentLow = this.findRecentLow(data, i, 20);
            
            // Check for liquidity sweep of high (bearish sweep)
            if (recentHigh && this.isSweepOfHigh(data, i, recentHigh, minSpikePoints, closeBackCandles)) {
                const sweep = {
                    type: 'liquiditySweep',
                    direction: 'bearish',
                    price: candle.high,
                    time: candle.time,
                    barIndex: i,
                    sweptLevel: recentHigh.price,
                    created: Date.now()
                };
                
                sweeps.push(sweep);
                this.newDetections.push(sweep);
            }
            
            // Check for liquidity sweep of low (bullish sweep)
            if (recentLow && this.isSweepOfLow(data, i, recentLow, minSpikePoints, closeBackCandles)) {
                const sweep = {
                    type: 'liquiditySweep',
                    direction: 'bullish',
                    price: candle.low,
                    time: candle.time,
                    barIndex: i,
                    sweptLevel: recentLow.price,
                    created: Date.now()
                };
                
                sweeps.push(sweep);
                this.newDetections.push(sweep);
            }
        }

        return sweeps;
    }

    findRecentHigh(data, currentIndex, lookback) {
        let highestPrice = 0;
        let highestIndex = -1;
        
        const startIndex = Math.max(0, currentIndex - lookback);
        
        for (let i = startIndex; i < currentIndex; i++) {
            if (data[i].high > highestPrice) {
                highestPrice = data[i].high;
                highestIndex = i;
            }
        }
        
        if (highestIndex === -1) return null;
        
        return {
            price: highestPrice,
            index: highestIndex,
            time: data[highestIndex].time
        };
    }

    findRecentLow(data, currentIndex, lookback) {
        let lowestPrice = Infinity;
        let lowestIndex = -1;
        
        const startIndex = Math.max(0, currentIndex - lookback);
        
        for (let i = startIndex; i < currentIndex; i++) {
            if (data[i].low < lowestPrice) {
                lowestPrice = data[i].low;
                lowestIndex = i;
            }
        }
        
        if (lowestIndex === -1) return null;
        
        return {
            price: lowestPrice,
            index: lowestIndex,
            time: data[lowestIndex].time
        };
    }

    isSweepOfHigh(data, currentIndex, recentHigh, minSpikePoints, closeBackCandles) {
        const candle = data[currentIndex];
        const spikeSize = candle.high - recentHigh.price;
        
        // Must spike above the high
        if (spikeSize <= 0) return false;
        
        // Check minimum spike size
        if (spikeSize < minSpikePoints * 0.0001) return false;
        
        // Check if price closes back within the swept range
        for (let i = currentIndex + 1; i <= Math.min(currentIndex + closeBackCandles, data.length - 1); i++) {
            if (data[i].close <= recentHigh.price) {
                return true;
            }
        }
        
        return false;
    }

    isSweepOfLow(data, currentIndex, recentLow, minSpikePoints, closeBackCandles) {
        const candle = data[currentIndex];
        const spikeSize = recentLow.price - candle.low;
        
        // Must spike below the low
        if (spikeSize <= 0) return false;
        
        // Check minimum spike size
        if (spikeSize < minSpikePoints * 0.0001) return false;
        
        // Check if price closes back within the swept range
        for (let i = currentIndex + 1; i <= Math.min(currentIndex + closeBackCandles, data.length - 1); i++) {
            if (data[i].close >= recentLow.price) {
                return true;
            }
        }
        
        return false;
    }

    detectStructureBreaks(data) {
        const structureBreaks = [];
        const swingLookback = this.config.get('swingLookback');
        const requiresSweep = this.config.get('structureRequiresSweep');

        // Find swing points
        const swingHighs = this.findSwingHighs(data, swingLookback);
        const swingLows = this.findSwingLows(data, swingLookback);

        // Detect BOS and CHoCH
        for (let i = swingLookback * 2; i < data.length; i++) {
            const candle = data[i];
            
            // Check for break of structure (BOS) - bullish
            const lastSwingLow = this.getLastSwingLow(swingLows, i);
            if (lastSwingLow && candle.close > lastSwingLow.price) {
                const structure = {
                    type: 'structureBreak',
                    structureType: 'BOS',
                    direction: 'bullish',
                    price: lastSwingLow.price,
                    time: candle.time,
                    barIndex: i,
                    brokenLevel: lastSwingLow,
                    created: Date.now()
                };
                
                structureBreaks.push(structure);
                this.newDetections.push(structure);
            }
            
            // Check for break of structure (BOS) - bearish
            const lastSwingHigh = this.getLastSwingHigh(swingHighs, i);
            if (lastSwingHigh && candle.close < lastSwingHigh.price) {
                const structure = {
                    type: 'structureBreak',
                    structureType: 'BOS',
                    direction: 'bearish',
                    price: lastSwingHigh.price,
                    time: candle.time,
                    barIndex: i,
                    brokenLevel: lastSwingHigh,
                    created: Date.now()
                };
                
                structureBreaks.push(structure);
                this.newDetections.push(structure);
            }
        }

        return structureBreaks;
    }

    findSwingHighs(data, lookback) {
        const swingHighs = [];
        
        for (let i = lookback; i < data.length - lookback; i++) {
            const candle = data[i];
            let isSwingHigh = true;
            
            // Check left side
            for (let j = i - lookback; j < i; j++) {
                if (data[j].high >= candle.high) {
                    isSwingHigh = false;
                    break;
                }
            }
            
            // Check right side
            if (isSwingHigh) {
                for (let j = i + 1; j <= i + lookback; j++) {
                    if (data[j].high >= candle.high) {
                        isSwingHigh = false;
                        break;
                    }
                }
            }
            
            if (isSwingHigh) {
                swingHighs.push({
                    price: candle.high,
                    index: i,
                    time: candle.time
                });
            }
        }
        
        return swingHighs;
    }

    findSwingLows(data, lookback) {
        const swingLows = [];
        
        for (let i = lookback; i < data.length - lookback; i++) {
            const candle = data[i];
            let isSwingLow = true;
            
            // Check left side
            for (let j = i - lookback; j < i; j++) {
                if (data[j].low <= candle.low) {
                    isSwingLow = false;
                    break;
                }
            }
            
            // Check right side
            if (isSwingLow) {
                for (let j = i + 1; j <= i + lookback; j++) {
                    if (data[j].low <= candle.low) {
                        isSwingLow = false;
                        break;
                    }
                }
            }
            
            if (isSwingLow) {
                swingLows.push({
                    price: candle.low,
                    index: i,
                    time: candle.time
                });
            }
        }
        
        return swingLows;
    }

    getLastSwingHigh(swingHighs, currentIndex) {
        for (let i = swingHighs.length - 1; i >= 0; i--) {
            if (swingHighs[i].index < currentIndex) {
                return swingHighs[i];
            }
        }
        return null;
    }

    getLastSwingLow(swingLows, currentIndex) {
        for (let i = swingLows.length - 1; i >= 0; i--) {
            if (swingLows[i].index < currentIndex) {
                return swingLows[i];
            }
        }
        return null;
    }

    updateZoneMitigation(zones, data) {
        const mitigationLevel = this.config.get('fvgMitigationLevel');
        
        zones.forEach(zone => {
            if (zone.status === 'mitigated') return;
            
            // Check for touches and mitigation
            for (let i = zone.barIndex + 1; i < data.length; i++) {
                const candle = data[i];
                
                if (this.isPriceInZone(candle, zone)) {
                    zone.touchCount++;
                    
                    // Check mitigation based on zone type
                    if (this.isZoneMitigated(candle, zone, mitigationLevel)) {
                        zone.status = 'mitigated';
                        zone.mitigatedAt = candle.time;
                        break;
                    }
                }
            }
        });
    }

    isPriceInZone(candle, zone) {
        return candle.low <= zone.high && candle.high >= zone.low;
    }

    isZoneMitigated(candle, zone, mitigationLevel) {
        const zoneHeight = zone.high - zone.low;
        const mitigationPrice = zone.direction === 'bullish' 
            ? zone.low + (zoneHeight * mitigationLevel)
            : zone.high - (zoneHeight * mitigationLevel);
        
        if (zone.direction === 'bullish') {
            return candle.low <= mitigationPrice;
        } else {
            return candle.high >= mitigationPrice;
        }
    }

    cleanOldZones(zones, data) {
        const deleteOlderThan = this.config.get('deleteObjectsOlderThan');
        if (deleteOlderThan <= 0) return;
        
        const cutoffTime = data[data.length - 1].time - (deleteOlderThan * 3600000); // Assuming hourly data
        
        for (let i = zones.length - 1; i >= 0; i--) {
            if (zones[i].timeStart < cutoffTime) {
                zones.splice(i, 1);
            }
        }
    }

    calculateExtendTime(startTime) {
        const extendBars = this.config.get('obExtendBars') || this.config.get('fvgExtendBars') || 50;
        return startTime + (extendBars * 3600000); // Assuming hourly timeframe
    }

    updateStatistics() {
        this.statistics = {
            orderBlocks: this.zones.filter(z => z.type === 'orderBlock').length,
            fairValueGaps: this.zones.filter(z => z.type === 'fairValueGap').length,
            liquiditySweeps: this.zones.filter(z => z.type === 'liquiditySweep').length,
            structureBreaks: this.zones.filter(z => z.type === 'structureBreak').length
        };
    }

    getStatistics() {
        return this.statistics;
    }

    getNewDetections() {
        const detections = [...this.newDetections];
        this.newDetections = []; // Clear after reading
        return detections;
    }

    getZones() {
        return this.zones;
    }
}
