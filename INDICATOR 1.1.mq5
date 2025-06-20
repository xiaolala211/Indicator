//+------------------------------------------------------------------+
//|                                               SMC_Visualizer.mq5 |
//|                                  Derived from SMC EA v2.0 Fixed  |
//|                                              https://www.mql5.com|
//+------------------------------------------------------------------+
#property copyright "Derived from SMC EA v2.0"
#property link      "https://www.mql5.com"
#property version   "1.01" // Version incremented
#property indicator_chart_window
#property indicator_buffers 0
#property indicator_plots   0

#include <Trade\SymbolInfo.mqh> // For _Point, Digits etc.

//+------------------------------------------------------------------+
//| Structures and Enumerations                                      |
//+------------------------------------------------------------------+
struct PriceZone {
    double high;         //
    double low;          //
    int    bar_index;    // // Represents shift from the current bar at the time of detection
    bool   isValid;      //
    int    touchCount;   //
    datetime firstCreated; //
    double mitigationLevel; //
    
    void PriceZone() {   //
        Reset();
    }
    
    void Reset() {       //
        high = 0;        //
        low = 0;         //
        bar_index = -1;  //
        isValid = false; //
        touchCount = 0;  //
        firstCreated = 0; //
        mitigationLevel = 0; //
    }
};

//+------------------------------------------------------------------+
//| Input Parameters                                                 |
//+------------------------------------------------------------------+
input group "═══ Order Blocks ═══";
input bool   InpDrawOrderBlocks = true; //
input int    InpOrderBlockLookbackPeriod = 30; //
input double InpMinMoveAfterOBFactor = 1.5; //
input int    InpMinImpulseCandles = 1; //
input color  InpBullishOBColor = clrDeepSkyBlue; //
input color  InpBearishOBColor = clrLightCoral; //
input ENUM_LINE_STYLE InpOB_Style = STYLE_SOLID; //
input int    InpOB_Width = 1; //
input bool   InpOB_Fill = true; //
input int    InpOB_Extend_Bars = 10; //

input group "═══ Fair Value Gaps ═══";
input bool   InpDrawFairValueGaps = true; //
input int    InpFVGLookbackPeriod = 30; //
input double InpMinFVGSizePoints = 50; //
input color  InpBullishFVGColor = clrLightSkyBlue; //
input color  InpBearishFVGColor = clrPink; //
input ENUM_LINE_STYLE InpFVG_Style = STYLE_DOT; //
input int    InpFVG_Width = 1; //
input bool   InpFVG_Fill = true; //
input int    InpFVG_Extend_Bars = 15; //

input group "═══ Liquidity Sweeps ═══";
input bool   InpDrawLiquiditySweeps = true; //
input double InpSweepMinSpikePoints = 10; //
input int    InpSweepCloseBackCandles = 1; //
input color  InpBullishLSColor = clrChartreuse; //
input color  InpBearishLSColor = clrOrangeRed; //
input int    InpArrowBullishSweepCode = 241; //
input int    InpArrowBearishSweepCode = 242; //

input group "═══ Structure Settings ═══";
input int    InpSwingLookback = 10; //
input int    InpStructuralSwingMinBars = 3; //

input group "═══ Object Management ═══";
input int    InpDeleteObjectsOlderThanNBars = 200; // Auto delete objects anchored on bars older than X bars from current (0 = disabled)

// Global Variables
CSymbolInfo symbolInfo;
string indicator_short_name;

//+------------------------------------------------------------------+
//| Delete objects by prefix                                         |
//+------------------------------------------------------------------+
void DeleteObjectsByPrefix(const string prefix) { //
    long chart_id = ChartID(); //
    // Iterate backwards as object count may change
    for(int i = ObjectsTotal(chart_id, 0, -1) - 1; i >= 0; i--) { //
        string obj_name = ObjectName(chart_id, i, 0, -1); //
        if(StringFind(obj_name, prefix) == 0) { // If object name starts with the prefix
            ObjectDelete(chart_id, obj_name); //
        }
    }
}

//+------------------------------------------------------------------+
//| Helper to delete all objects managed by this indicator           |
//+------------------------------------------------------------------+
void DeleteAllIndicatorObjects() {
    DeleteObjectsByPrefix("SMC_BullishOB_");
    DeleteObjectsByPrefix("SMC_BearishOB_");
    DeleteObjectsByPrefix("SMC_BullishFVG_");
    DeleteObjectsByPrefix("SMC_BearishFVG_");
    DeleteObjectsByPrefix("SMC_LS_");
}

//+------------------------------------------------------------------+
//| Get bar shift by time (0 for current bar, 1 for previous, etc.)  |
//+------------------------------------------------------------------+
int GetShiftByTime(datetime time_to_find) {
    datetime times_array[];
    int bars_total = Bars(_Symbol, _Period);
    if(bars_total <= 0) return -1;

    // Copy all time values. For very long histories, this might be slow,
    // but it's reliable. Consider optimizing if performance is an issue here.
    if(CopyTime(_Symbol, _Period, 0, bars_total, times_array) != bars_total) {
        // PrintFormat("Error in CopyTime for GetShiftByTime: %d", GetLastError());
        return -1;
    }
    ArraySetAsSeries(times_array, true); // times_array[0] is current bar's time (shift 0)

    for(int i = 0; i < ArraySize(times_array); i++) {
        if(times_array[i] == time_to_find) {
            return i; // Exact match for bar open time
        }
        // Check if time_to_find falls within the bar starting at times_array[i]
        if(times_array[i] < time_to_find) {
            if (i == 0) return i; // time_to_find is within the current bar (index 0)
            // If times_array[i] < time_to_find and (previous bar's time) times_array[i-1] > time_to_find
            if (i > 0 && times_array[i-1] > time_to_find) {
                 return i; // time_to_find is within the bar whose open time is times_array[i]
            }
        }
    }
    // PrintFormat("Time %s not found in GetShiftByTime within %d bars", TimeToString(time_to_find), bars_total);
    return -1; // Not found or time is older than available history
}


//+------------------------------------------------------------------+
//| Cleanup old objects based on their anchor bar's age              |
//+------------------------------------------------------------------+
void CleanupOldObjects(int max_age_bars_ago) {
    if (max_age_bars_ago <= 0) return; // Feature disabled

    long chart_id = ChartID();
    string obj_names_to_delete[]; // Store names to delete to avoid modifying collection while iterating

    for(int i = ObjectsTotal(chart_id, 0, -1) - 1; i >= 0; i--) {
        string current_obj_name = ObjectName(chart_id, i, 0, -1);
        
        bool is_smc_object = (StringFind(current_obj_name, "SMC_BullishOB_") == 0 ||
                              StringFind(current_obj_name, "SMC_BearishOB_") == 0 ||
                              StringFind(current_obj_name, "SMC_BullishFVG_") == 0 ||
                              StringFind(current_obj_name, "SMC_BearishFVG_") == 0 ||
                              StringFind(current_obj_name, "SMC_LS_") == 0);

        if (is_smc_object) {
            datetime obj_anchor_time = (datetime)ObjectGetInteger(chart_id, current_obj_name, OBJPROP_TIME, 0);
            if (obj_anchor_time == 0) continue; // Invalid object time

            int obj_bar_shift = GetShiftByTime(obj_anchor_time);

            if (obj_bar_shift != -1 && obj_bar_shift >= max_age_bars_ago) {
             int current_array_size = ArraySize(obj_names_to_delete);
if (ArrayResize(obj_names_to_delete, current_array_size + 1) == current_array_size + 1) {
    obj_names_to_delete[current_array_size] = current_obj_name;
} else {
    Print("CleanupOldObjects: ArrayResize failed for obj_names_to_delete. Error: ", GetLastError());
}
            }
        }
    }

    for(int i = 0; i < ArraySize(obj_names_to_delete); i++) {
        ObjectDelete(chart_id, obj_names_to_delete[i]);
    }
    // No ChartRedraw() here, it will be called at the end of OnCalculate
}


//+------------------------------------------------------------------+
//| Draw Order Block                                                 |
//+------------------------------------------------------------------+
void DrawOrderBlock(const PriceZone &zone, color ob_color, string ob_name_prefix, ENUM_TIMEFRAMES timeframe,
                    ENUM_LINE_STYLE style, int width, bool fill, int extend_bars) { //
    string name = StringFormat("%s_%s_%d", ob_name_prefix, EnumToString(timeframe), zone.bar_index); //
    
    // zone.bar_index here is the 'shift' (bars ago from current calculation point) where the OB candle was identified.
    // The actual time of this bar is iTime(_Symbol, timeframe, zone.bar_index)
    datetime time1 = iTime(_Symbol, timeframe, zone.bar_index); //
    if (time1 == 0 && zone.bar_index != 0) { // Error getting time, unless it's the current forming bar (shift 0)
         // PrintFormat("Error getting time1 for OB %s, bar_index: %d", name, zone.bar_index);
         return; 
    }


    if (ObjectFind(0, name) != -1) {
        // Check if the existing object is anchored at the correct time for this bar_index
        if (time1 == ObjectGetInteger(0, name, OBJPROP_TIME, 0)) {
            datetime time2_current = iTime(_Symbol, timeframe, 0) + PeriodSeconds(timeframe) * extend_bars;
            ObjectSetInteger(0, name, OBJPROP_TIME, 1, time2_current);
            // Object properties like color, style, width, fill are assumed to be unchanged if object exists for same bar.
            return; // Object exists and is for the same bar index, updated its right extend
        } else {
            // Object with same name exists but for a different original bar time. This scenario
            // should be rare if bar_index in name correctly identifies the formation bar.
            // Delete it to redraw correctly.
            ObjectDelete(0, name);
        }
    }
    
    // If time1 is 0 and zone.bar_index is 0, it means the current forming bar.
    // For CopyRates, bar 0 is the current forming bar. iTime(_Symbol, timeframe, 0) is its open time.
    // This is fine.

    datetime time2 = iTime(_Symbol, timeframe, 0) + PeriodSeconds(timeframe) * extend_bars; // Extend X bars from current bar
    
    if (!ObjectCreate(0, name, OBJ_RECTANGLE, 0, time1, zone.high, time2, zone.low)) { //
        // PrintFormat("Error creating OB rectangle object %s. Error: %d. Time1: %s, High: %f, Time2: %s, Low: %f", 
        //             name, GetLastError(), TimeToString(time1), zone.high, TimeToString(time2), zone.low);
        return;
    }
    
    ObjectSetInteger(0, name, OBJPROP_COLOR, ob_color); //
    ObjectSetInteger(0, name, OBJPROP_STYLE, style); //
    ObjectSetInteger(0, name, OBJPROP_WIDTH, width); //
    ObjectSetInteger(0, name, OBJPROP_FILL, fill); //
    ObjectSetInteger(0, name, OBJPROP_BACK, true); //
    ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false); //
    ObjectSetString(0, name, OBJPROP_TOOLTIP, StringFormat("OB H:%.5f L:%.5f (Bar Ago: %d)", zone.high, zone.low, zone.bar_index)); //
}

//+------------------------------------------------------------------+
//| Draw Fair Value Gap                                              |
//+------------------------------------------------------------------+
void DrawFairValueGap(const PriceZone &zone, color fvg_color, string fvg_name_prefix, ENUM_TIMEFRAMES timeframe,
                      ENUM_LINE_STYLE style, int width, bool fill, int extend_bars) { //
    string name = StringFormat("%s_%s_%d", fvg_name_prefix, EnumToString(timeframe), zone.bar_index); //

    // zone.bar_index for FVG is the middle candle of the 3-bar pattern (e.g., i+1 in FindBullishFVG)
    datetime time1 = iTime(_Symbol, timeframe, zone.bar_index); //
     if (time1 == 0 && zone.bar_index != 0) {
        // PrintFormat("Error getting time1 for FVG %s, bar_index: %d", name, zone.bar_index);
        return;
    }

    if (ObjectFind(0, name) != -1) {
         if (time1 == ObjectGetInteger(0, name, OBJPROP_TIME, 0) ) {
            datetime time2_current = iTime(_Symbol, timeframe, 0) + PeriodSeconds(timeframe) * extend_bars;
            ObjectSetInteger(0, name, OBJPROP_TIME, 1, time2_current);
            return;
        } else {
            ObjectDelete(0,name);
        }
    }

    datetime time2 = iTime(_Symbol, timeframe, 0) + PeriodSeconds(timeframe) * extend_bars; // Extend X bars from current bar

    if (!ObjectCreate(0, name, OBJ_RECTANGLE, 0, time1, zone.high, time2, zone.low)) { //
        // PrintFormat("Error creating FVG rectangle object %s. Error: %d. Time1: %s, High: %f, Time2: %s, Low: %f", 
        //             name, GetLastError(), TimeToString(time1), zone.high, TimeToString(time2), zone.low);
        return;
    }
    
    ObjectSetInteger(0, name, OBJPROP_COLOR, fvg_color); //
    ObjectSetInteger(0, name, OBJPROP_STYLE, style); //
    ObjectSetInteger(0, name, OBJPROP_WIDTH, width); //
    ObjectSetInteger(0, name, OBJPROP_FILL, fill); //
    ObjectSetInteger(0, name, OBJPROP_BACK, true); //
    ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false); //
    ObjectSetString(0, name, OBJPROP_TOOLTIP, StringFormat("FVG H:%.5f L:%.5f (Bar Ago: %d)", zone.high, zone.low, zone.bar_index)); //
}

//+------------------------------------------------------------------+
//| Draw Liquidity Sweep Marker                                      |
//+------------------------------------------------------------------+
void DrawLiquiditySweepMarker(ENUM_TIMEFRAMES timeframe, const PriceZone &sweep_candle_info, // Info of the candle that performed the sweep
                              const PriceZone &swept_level_info,   // Info of the swing high/low that was swept
                              bool is_bullish_sweep,
                              color sweep_color, int arrow_code) { 
    // sweep_candle_info.bar_index is the shift of the candle that spiked and closed back
    string name = StringFormat("SMC_LS_%s_%d", is_bullish_sweep ? "Bull" : "Bear", sweep_candle_info.bar_index); 
    if (ObjectFind(0, name) != -1) return; // Already drawn

    datetime time = iTime(_Symbol, timeframe, sweep_candle_info.bar_index); 
    if (time == 0 && sweep_candle_info.bar_index !=0 ) {
        // PrintFormat("Error getting time for LS marker %s, bar_index: %d", name, sweep_candle_info.bar_index);
        return; 
    }

    double price_offset = (_Point * 10) * 10; 
    double price_level_for_arrow;
    if(is_bullish_sweep) { // Bullish sweep: price spiked BELOW a low then closed above. Arrow points UP from below the low.
        price_level_for_arrow = MathMin(sweep_candle_info.low, swept_level_info.low) - price_offset;
    } else { // Bearish sweep: price spiked ABOVE a high then closed below. Arrow points DOWN from above the high.
        price_level_for_arrow = MathMax(sweep_candle_info.high, swept_level_info.high) + price_offset;
    }

    if (!ObjectCreate(0, name, OBJ_ARROW, 0, time, price_level_for_arrow)) { 
        // PrintFormat("Error creating LS arrow object %s. Error: %d", name, GetLastError()); 
        return;
    }

    ObjectSetInteger(0, name, OBJPROP_ARROWCODE, arrow_code); 
    ObjectSetInteger(0, name, OBJPROP_COLOR, sweep_color); 
    ObjectSetInteger(0, name, OBJPROP_WIDTH, 1); 
    ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false); 
    ObjectSetString(0, name, OBJPROP_TOOLTIP, StringFormat("Sweep @ %.5f (Swept Level: %.5f, Bar Ago: %d)",
                    is_bullish_sweep ? sweep_candle_info.low : sweep_candle_info.high,
                    is_bullish_sweep ? swept_level_info.low : swept_level_info.high,
                    sweep_candle_info.bar_index)); 
}
//+------------------------------------------------------------------+
//| SMC Pattern Detection Functions (Adapted from EA)                |
//+------------------------------------------------------------------+
PriceZone FindBullishOrderBlock(ENUM_TIMEFRAMES timeframe, int ob_lookback_period, double min_move_factor, int min_impulse_candles, int shift) { //
    PriceZone ob;
    MqlRates localRates[];
    ArraySetAsSeries(localRates, true); //

    int rates_to_copy = ob_lookback_period + min_impulse_candles + shift + 5; //
    if (CopyRates(_Symbol, timeframe, 0, rates_to_copy, localRates) < rates_to_copy) { // Copy from current bar going back
        //PrintFormat("Error copying rates for Bullish OB detection on %s (shift %d): %d", EnumToString(timeframe), shift, GetLastError()); //
        return ob; //
    }
    
    for (int i = shift + min_impulse_candles; i < shift + ob_lookback_period + min_impulse_candles; i++) { // 'i' is the index in localRates, representing bar 'i' ago
        if (i >= ArraySize(localRates) -1 ) break; //
        
        if (localRates[i].close < localRates[i].open) { // Potential bearish OB candle (last down candle before up move)
            bool strong_bullish_move = true; //
            double total_impulse_move_range = 0; //
            double highest_high_after_ob = 0; // Initialize with a value that will be overcome

            if (min_impulse_candles <= 0) { // If no impulse candles required, the logic might need specific handling
                 strong_bullish_move = true; // Assume true, or define specific conditions
                 // For this pattern, typically min_impulse_candles >= 1
            } else {
                for(int k=0; k < min_impulse_candles; k++) { //
                    int impulse_candle_idx = i - 1 - k; // Candles after (newer than) the OB candle
                    
                    if (impulse_candle_idx < shift ) { // Impulse candles must be within the 'shift' boundary (newer than or at 'shift')
                                                     // This check ensures impulse candles are not older than the 'shift' point from current bar 0.
                                                     // Example: shift = 5. OB candle is at i=7. Impulse candle 1 is at 6. Impulse candle 2 is at 5. All >= shift.
                                                     // If an impulse_candle_idx becomes < shift, it means it's trying to look at a candle
                                                     // that is 'too new' relative to the window defined by 'shift'.
                                                     // This condition seems to prevent looking at candles newer than 'shift' for the impulse.
                                                     // Original intent: impulse_candle_idx must be >= 0 and also >= shift if shift itself is a constraint on recency of impulse.
                                                     // Correct logic: impulse candles are between OB (i) and 'shift'.
                        if (impulse_candle_idx < 0 || impulse_candle_idx < shift) { // Ensure impulse candles are valid and not newer than 'shift' position
                            strong_bullish_move = false; 
                            break; 
                        }
                    }


                    if (localRates[impulse_candle_idx].close <= localRates[impulse_candle_idx].open) { // Impulse must be bullish
                        strong_bullish_move = false; //
                        break; //
                    }
                    if (localRates[impulse_candle_idx].high > highest_high_after_ob) { //
                        highest_high_after_ob = localRates[impulse_candle_idx].high; //
                    }
                    total_impulse_move_range += (localRates[impulse_candle_idx].high - localRates[impulse_candle_idx].low); //
                }
            }
            
            if (!strong_bullish_move && min_impulse_candles > 0) continue; //
            
            double ob_candle_body = localRates[i].open - localRates[i].close; //
            if (ob_candle_body <=0) ob_candle_body = _Point; // Avoid division by zero for doji

            // Condition: impulse move broke the high of the OB candle, and the move was significant
            if ( (min_impulse_candles == 0 || highest_high_after_ob > localRates[i].high) && 
                  total_impulse_move_range >= ob_candle_body * min_move_factor) { //
                ob.high = localRates[i].high; //
                ob.low = localRates[i].low; //
                ob.bar_index = i; // Bar index relative to current bar (0) when CopyRates was called
                ob.isValid = true; //
                return ob; //
            }
        }
    }
    return ob; //
}

PriceZone FindBearishOrderBlock(ENUM_TIMEFRAMES timeframe, int ob_lookback_period, double min_move_factor, int min_impulse_candles, int shift) { //
    PriceZone ob;
    MqlRates localRates[];
    ArraySetAsSeries(localRates, true); //

    int rates_to_copy = ob_lookback_period + min_impulse_candles + shift + 5; //
    if (CopyRates(_Symbol, timeframe, 0, rates_to_copy, localRates) < rates_to_copy) { //
        //PrintFormat("Error copying rates for Bearish OB detection on %s (shift %d): %d", EnumToString(timeframe), shift, GetLastError()); //
        return ob; //
    }

    for (int i = shift + min_impulse_candles; i < shift + ob_lookback_period + min_impulse_candles; i++) { //
        if (i >= ArraySize(localRates)-1) break; //
        
        if (localRates[i].close > localRates[i].open) { // Potential bullish OB candle (last up candle before down move)
            bool strong_bearish_move = true; //
            double total_impulse_move_range = 0; //
            double lowest_low_after_ob = DBL_MAX;  // Initialize with a value that will be overcome (Fixed from WRONG_VALUE)

            if (min_impulse_candles <= 0) {
                strong_bearish_move = true; 
            } else {
                for(int k=0; k < min_impulse_candles; k++) { //
                    int impulse_candle_idx = i - 1 - k; //
                     if (impulse_candle_idx < 0 || impulse_candle_idx < shift) { // Ensure impulse candles are valid and not newer than 'shift' position
                        strong_bearish_move = false; 
                        break; 
                    }

                    if (localRates[impulse_candle_idx].close >= localRates[impulse_candle_idx].open) { // Impulse must be bearish
                        strong_bearish_move = false; //
                        break; //
                    }
                    if (localRates[impulse_candle_idx].low < lowest_low_after_ob) { //
                        lowest_low_after_ob = localRates[impulse_candle_idx].low; //
                    }
                    total_impulse_move_range += (localRates[impulse_candle_idx].high - localRates[impulse_candle_idx].low); //
                }
            }

            if (!strong_bearish_move && min_impulse_candles > 0) continue; //
            if (lowest_low_after_ob == DBL_MAX && min_impulse_candles > 0) continue; // Added check: if no valid impulse low was found

            double ob_candle_body = localRates[i].close - localRates[i].open; //
            if(ob_candle_body <= 0) ob_candle_body = _Point; // Avoid division by zero for doji

            if ( (min_impulse_candles == 0 || lowest_low_after_ob < localRates[i].low) && 
                 total_impulse_move_range >= ob_candle_body * min_move_factor) { //
                ob.high = localRates[i].high; //
                ob.low = localRates[i].low; //
                ob.bar_index = i; //
                ob.isValid = true; //
                return ob; //
            }
        }
    }
    return ob; //
}

PriceZone FindBullishFVG(ENUM_TIMEFRAMES timeframe, int fvg_lookback_period, double min_fvg_size_points, int shift) { //
    PriceZone fvg;
    MqlRates localRates[];
    ArraySetAsSeries(localRates, true); //
    
    int rates_to_copy = fvg_lookback_period + 3 + shift; //
    if (CopyRates(_Symbol, timeframe, 0, rates_to_copy, localRates) < rates_to_copy) { //
        //PrintFormat("Error copying rates for Bullish FVG detection on %s (shift %d): %d", EnumToString(timeframe), shift, GetLastError()); //
        return fvg; //
    }

    for (int i = shift; i < shift + fvg_lookback_period; i++) { // i is the index of candle3 (the newest of the 3-bar pattern, relative to current bar 0)
        if (i + 2 >= ArraySize(localRates)) { //
            break;  
        }

        MqlRates candle3 = localRates[i];     // Newest candle (bar 'i' ago)
        MqlRates candle2 = localRates[i+1]; // Middle candle (bar 'i+1' ago)
        MqlRates candle1 = localRates[i+2]; // Oldest candle (bar 'i+2' ago)
        
        if (candle1.high < candle3.low) { // Bullish FVG condition (high of 1st < low of 3rd)
            double fvg_size_actual_points = (candle3.low - candle1.high) / symbolInfo.Point(); //
            if (min_fvg_size_points > 0 && fvg_size_actual_points < min_fvg_size_points) { //
                continue; //
            }

            fvg.high = candle3.low; //
            fvg.low = candle1.high; //
            fvg.bar_index = i + 1; // FVG is associated with the middle candle (candle2), shift is i+1
            fvg.isValid = true; //
            return fvg; //
        }
    }
    return fvg; //
}

PriceZone FindBearishFVG(ENUM_TIMEFRAMES timeframe, int fvg_lookback_period, double min_fvg_size_points, int shift) { //
    PriceZone fvg;
    MqlRates localRates[];
    ArraySetAsSeries(localRates, true); //
    
    int rates_to_copy = fvg_lookback_period + 3 + shift; //
    if (CopyRates(_Symbol, timeframe, 0, rates_to_copy, localRates) < rates_to_copy) { //
       // PrintFormat("Error copying rates for Bearish FVG detection on %s (shift %d): %d", EnumToString(timeframe), shift, GetLastError()); //
        return fvg; //
    }

    for (int i = shift; i < shift + fvg_lookback_period; i++) { //
        if (i + 2 >= ArraySize(localRates)) { //
            break;
        }

        MqlRates candle3 = localRates[i];     // Newest candle
        MqlRates candle2 = localRates[i+1]; // Middle candle
        MqlRates candle1 = localRates[i+2]; // Oldest candle

        if (candle1.low > candle3.high) { // Bearish FVG condition (low of 1st > high of 3rd)
            double fvg_size_actual_points = (candle1.low - candle3.high) / symbolInfo.Point(); //
            if (min_fvg_size_points > 0 && fvg_size_actual_points < min_fvg_size_points) { //
                continue; //
            }
            
            fvg.high = candle1.low; //
            fvg.low = candle3.high; //
            fvg.bar_index = i + 1; // FVG is associated with the middle candle (candle2)
            fvg.isValid = true; //
            return fvg; //
        }
    }
    return fvg; //
}

PriceZone GetLastSignificantSwingHigh(ENUM_TIMEFRAMES timeframe, int lookback_range, int N, int shift_start) { //
    PriceZone swing_high;
    MqlRates localRates[];
    ArraySetAsSeries(localRates, true); //
    
    if (N < 1) N = 1;

    int rates_to_copy = shift_start + lookback_range + N + N +1; // +N for left side, +N for right side
    if (CopyRates(_Symbol, timeframe, 0, rates_to_copy, localRates) < rates_to_copy) { //
        //PrintFormat("Error copying rates for GetLastSignificantSwingHigh on %s (shift_start %d): %d", EnumToString(timeframe), shift_start, GetLastError()); //
        return swing_high; //
    }

    for (int candidate_idx = shift_start + N; candidate_idx < shift_start + lookback_range + N; candidate_idx++) { //
        if (candidate_idx >= ArraySize(localRates) - N || candidate_idx - N < 0) { // Ensure enough data for N bars on both sides
            break;  
        }

        bool is_swing_high = true; //
        double candidate_high_price = localRates[candidate_idx].high; //

        // Check N bars to the right (older candles in localRates, which is series)
        for (int j = 1; j <= N; j++) { //
            if (localRates[candidate_idx + j].high >= candidate_high_price) { //
                is_swing_high = false; //
                break; //
            }
        }
        if (!is_swing_high) continue; //

        // Check N bars to the left (newer candles in localRates)
        for (int j = 1; j <= N; j++) { //
            if (localRates[candidate_idx - j].high > candidate_high_price) { // Strict: candidate must be the unique highest
                is_swing_high = false; //
                break; //
            }
        }

        if (is_swing_high) { //
            swing_high.high = candidate_high_price; //
            swing_high.low = localRates[candidate_idx].low; //
            swing_high.bar_index = candidate_idx; // This is the shift (bars ago) of the swing high candle
            swing_high.isValid = true; //
            return swing_high; //
        }
    }
    return swing_high; //
}

PriceZone GetLastSignificantSwingLow(ENUM_TIMEFRAMES timeframe, int lookback_range, int N, int shift_start) { //
    PriceZone swing_low;
    MqlRates localRates[];
    ArraySetAsSeries(localRates, true); //
    if (N < 1) N = 1;

    int rates_to_copy = shift_start + lookback_range + N + N + 1; //
    if (CopyRates(_Symbol, timeframe, 0, rates_to_copy, localRates) < rates_to_copy) { //
        //PrintFormat("Error copying rates for GetLastSignificantSwingLow on %s (shift_start %d): %d", EnumToString(timeframe), shift_start, GetLastError()); //
        return swing_low; //
    }

    for (int candidate_idx = shift_start + N; candidate_idx < shift_start + lookback_range + N; candidate_idx++) { //
         if (candidate_idx >= ArraySize(localRates) - N || candidate_idx - N < 0) { //
            break;
        }

        bool is_swing_low = true; //
        double candidate_low_price = localRates[candidate_idx].low; //

        // Check N bars to the right (older candles)
        for (int j = 1; j <= N; j++) { //
            if (localRates[candidate_idx + j].low <= candidate_low_price) { //
                is_swing_low = false; //
                break; //
            }
        }
        if (!is_swing_low) continue; //

        // Check N bars to the left (newer candles)
        for (int j = 1; j <= N; j++) { //
            if (localRates[candidate_idx - j].low < candidate_low_price) { // Strict: candidate must be the unique lowest
                is_swing_low = false; //
                break; //
            }
        }

        if (is_swing_low) { //
            swing_low.low = candidate_low_price; //
            swing_low.high = localRates[candidate_idx].high; //
            swing_low.bar_index = candidate_idx; //
            swing_low.isValid = true; //
            return swing_low; //
        }
    }
    return swing_low; //
}

bool CheckAndGetBullishLiquiditySweep(ENUM_TIMEFRAMES timeframe, const PriceZone &prev_swing_low,
                                      double min_spike_points, int max_close_back_candles,
                                      PriceZone &sweep_candle_info, int check_bar_shift) { //
    sweep_candle_info.Reset(); //
    if (!prev_swing_low.isValid) return false; //
    if (check_bar_shift < 0) return false; // Cannot check future bars (relative to current pattern detection point)

    // prev_swing_low.bar_index is the shift of the swing low (e.g., 10 bars ago)
    // check_bar_shift is the shift of the candle we are checking for the sweep (e.g., 5 bars ago)
    // The swing low must be older than the sweep candle.
    // So, prev_swing_low.bar_index must be > check_bar_shift.
    if (prev_swing_low.bar_index <= check_bar_shift) return false; //


    MqlRates candidate_rates[];
    // Need rates up to prev_swing_low.bar_index to compare, and around check_bar_shift
    // Max shift needed is prev_swing_low.bar_index.
    // Rates are copied from current bar (0) backwards.
    // check_bar_shift and candles around it are needed.
    int total_candles_needed = MathMax(prev_swing_low.bar_index, check_bar_shift + max_close_back_candles) + 2; //
    if(CopyRates(_Symbol, timeframe, 0, total_candles_needed, candidate_rates) < total_candles_needed) return false; //
    ArraySetAsSeries(candidate_rates, true); //

    if (check_bar_shift >= ArraySize(candidate_rates) || prev_swing_low.bar_index >= ArraySize(candidate_rates)) return false; // Not enough data

    double sweep_low_price = candidate_rates[check_bar_shift].low; //
    double actual_spike_points = (prev_swing_low.low - sweep_low_price) / symbolInfo.Point(); //


    if (sweep_low_price < prev_swing_low.low && (min_spike_points == 0 || actual_spike_points >= min_spike_points)) { //
        // Now check if price closes back above the prev_swing_low.low within max_close_back_candles
        // The candles for this check are newer than or equal to check_bar_shift
        for (int k = 0; k < max_close_back_candles; k++) { //
            // confirmation_candle_idx is the shift of the candle that closes back.
            // It must be newer than or equal to check_bar_shift.
            // k=0 means the sweep candle itself (check_bar_shift) closes back.
            // k=1 means one bar after sweep candle (check_bar_shift - 1) closes back.
            int confirmation_candle_idx = check_bar_shift - k; 
            if (confirmation_candle_idx < 0) break; // // Gone past current bar 0
            if (confirmation_candle_idx >= ArraySize(candidate_rates)) continue; // Should not happen with total_candles_needed logic


            if (candidate_rates[confirmation_candle_idx].close > prev_swing_low.low) { //
                // Information of the candle that spiked (at check_bar_shift)
                sweep_candle_info.high = candidate_rates[check_bar_shift].high; 
                sweep_candle_info.low = candidate_rates[check_bar_shift].low; 
                sweep_candle_info.bar_index = check_bar_shift; // This is the shift of the candle that took liquidity. The marker will be here.
                sweep_candle_info.isValid = true; 
                return true; 
            }
        }
    }
    return false; //
}

bool CheckAndGetBearishLiquiditySweep(ENUM_TIMEFRAMES timeframe, const PriceZone &prev_swing_high,
                                      double min_spike_points, int max_close_back_candles,
                                      PriceZone &sweep_candle_info, int check_bar_shift) { //
    sweep_candle_info.Reset(); //
    if (!prev_swing_high.isValid) return false; //
    if (check_bar_shift < 0) return false;

    if (prev_swing_high.bar_index <= check_bar_shift) return false; // Swing high must be older

    MqlRates candidate_rates[];
    int total_candles_needed = MathMax(prev_swing_high.bar_index, check_bar_shift + max_close_back_candles) + 2; //
    if(CopyRates(_Symbol, timeframe, 0, total_candles_needed, candidate_rates) < total_candles_needed) return false; //
    ArraySetAsSeries(candidate_rates, true); //

    if (check_bar_shift >= ArraySize(candidate_rates) || prev_swing_high.bar_index >= ArraySize(candidate_rates)) return false;

    double sweep_high_price = candidate_rates[check_bar_shift].high; //
    double actual_spike_points = (sweep_high_price - prev_swing_high.high) / symbolInfo.Point(); //


    if (sweep_high_price > prev_swing_high.high && (min_spike_points == 0 || actual_spike_points >= min_spike_points)) { //
        for (int k = 0; k < max_close_back_candles; k++) { //
            int confirmation_candle_idx = check_bar_shift - k; //
            if (confirmation_candle_idx < 0) break; //
            if (confirmation_candle_idx >= ArraySize(candidate_rates)) continue;

            if (candidate_rates[confirmation_candle_idx].close < prev_swing_high.high) { //
                sweep_candle_info.high = candidate_rates[check_bar_shift].high; //
                sweep_candle_info.low = candidate_rates[check_bar_shift].low; //
                sweep_candle_info.bar_index = check_bar_shift; //
                sweep_candle_info.isValid = true; //
                return true; //
            }
        }
    }
    return false; //
}


//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit() {
    if(!symbolInfo.Name(_Symbol)) {
        Print("ERROR: Failed to initialize symbol info for indicator"); //
        return INIT_FAILED; //
    }
    symbolInfo.RefreshRates(); // Load initial rates info

    indicator_short_name = "SMC Visualizer " + (string)InpDeleteObjectsOlderThanNBars; // Add param to name for uniqueness if params change
    IndicatorSetString(INDICATOR_SHORTNAME, indicator_short_name);
    
    // Clean up objects from previous instances if any (especially if indicator was recompiled/reloaded quickly)
    // OnDeinit should handle this, but this is an extra safety for init phase.
    DeleteAllIndicatorObjects();

    return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[]) {
    
    if (IsStopped()) return 0;

    // --- 1. Auto-delete very old objects based on InpDeleteObjectsOlderThanNBars ---
    if (InpDeleteObjectsOlderThanNBars > 0) {
        CleanupOldObjects(InpDeleteObjectsOlderThanNBars);
    }

    // --- 2. Determine calculation range ---
    int start_bar;
    if(prev_calculated == 0 || rates_total < prev_calculated || prev_calculated > rates_total + 10) { // First run, major history update, or significant discrepancy
        start_bar = MathMax(0, rates_total - 1 - MathMax(InpOrderBlockLookbackPeriod, InpFVGLookbackPeriod) - InpSwingLookback - MathMax(InpOB_Extend_Bars, InpFVG_Extend_Bars) - 20); // Go back further on first run
        DeleteAllIndicatorObjects(); // Clean all drawings for a full recalculation/redraw
    } else {
        // Incremental update: calculate start_bar to cover relevant recent history for pattern detection and extension.
        // This ensures that existing objects that need their 'extend_bars' property updated are re-evaluated.
        // The drawing functions themselves are optimized to only update extension if the pattern is re-confirmed.
        int effective_lookback = MathMax(InpOrderBlockLookbackPeriod + InpMinImpulseCandles, InpFVGLookbackPeriod + 3); // Max depth for pattern elements
        effective_lookback = MathMax(effective_lookback, InpSwingLookback + InpStructuralSwingMinBars); // Consider swing lookback for LS
        int extension_influence = MathMax(InpOB_Extend_Bars, InpFVG_Extend_Bars) + 5; // How far extension might influence recalculation depth needed
        
        start_bar = rates_total - 1 - (effective_lookback + extension_influence);
        start_bar = MathMax(0, start_bar); // Ensure non-negative
        
        // If prev_calculated is close to rates_total, we might optimize further,
        // but the current approach ensures objects are correctly extended.
        // The `return` statements in drawing functions for existing objects are key to performance here.
    }
    if (start_bar >= rates_total && rates_total > 0) start_bar = rates_total -1; // Ensure start_bar is valid

    // --- 3. Loop through bars for pattern detection and drawing ---
    // Loop from older relevant bars to newer ones.
    // `current_processing_shift` is how many bars ago (from current bar 0) we are looking for a pattern.
    for (int i = start_bar; i < rates_total; i++) {
        if (IsStopped()) break;
        int current_processing_shift = rates_total - 1 - i; 
        if(current_processing_shift < 0) continue; // Should not happen with correct loop bounds

        // --- Order Blocks ---
        if (InpDrawOrderBlocks) {
            PriceZone bullishOB = FindBullishOrderBlock(_Period, InpOrderBlockLookbackPeriod, InpMinMoveAfterOBFactor, InpMinImpulseCandles, current_processing_shift); //
            if (bullishOB.isValid) {
                DrawOrderBlock(bullishOB, InpBullishOBColor, "SMC_BullishOB", _Period, InpOB_Style, InpOB_Width, InpOB_Fill, InpOB_Extend_Bars); //
            }
            PriceZone bearishOB = FindBearishOrderBlock(_Period, InpOrderBlockLookbackPeriod, InpMinMoveAfterOBFactor, InpMinImpulseCandles, current_processing_shift); //
            if (bearishOB.isValid) {
                DrawOrderBlock(bearishOB, InpBearishOBColor, "SMC_BearishOB", _Period, InpOB_Style, InpOB_Width, InpOB_Fill, InpOB_Extend_Bars); //
            }
        }

        // --- Fair Value Gaps ---
        if (InpDrawFairValueGaps) {
            PriceZone bullishFVG = FindBullishFVG(_Period, InpFVGLookbackPeriod, InpMinFVGSizePoints, current_processing_shift); //
            if (bullishFVG.isValid) {
                DrawFairValueGap(bullishFVG, InpBullishFVGColor, "SMC_BullishFVG", _Period, InpFVG_Style, InpFVG_Width, InpFVG_Fill, InpFVG_Extend_Bars); //
            }
            PriceZone bearishFVG = FindBearishFVG(_Period, InpFVGLookbackPeriod, InpMinFVGSizePoints, current_processing_shift); //
            if (bearishFVG.isValid) {
                DrawFairValueGap(bearishFVG, InpBearishFVGColor, "SMC_BearishFVG", _Period, InpFVG_Style, InpFVG_Width, InpFVG_Fill, InpFVG_Extend_Bars); //
            }
        }
        
        // --- Liquidity Sweeps ---
        // A sweep is identified at `current_processing_shift`. The swing it swept must be older.
        if(InpDrawLiquiditySweeps) {
            // Bullish Sweep (sweeping a low)
            // Look for a swing low that is older than `current_processing_shift`.
            // `shift_start` for swing search begins from `current_processing_shift + 1` (one bar older than the potential sweep candle).
            PriceZone prev_low = GetLastSignificantSwingLow(_Period, InpSwingLookback, InpStructuralSwingMinBars, current_processing_shift + 1); //
            PriceZone sweep_bull_info;
            // Check if the bar at `current_processing_shift` swept this `prev_low`.
            if(prev_low.isValid && CheckAndGetBullishLiquiditySweep(_Period, prev_low, InpSweepMinSpikePoints, InpSweepCloseBackCandles, sweep_bull_info, current_processing_shift)) { //
                 DrawLiquiditySweepMarker(_Period, sweep_bull_info, prev_low, true, InpBullishLSColor, InpArrowBullishSweepCode); //
            }

            // Bearish Sweep (sweeping a high)
            PriceZone prev_high = GetLastSignificantSwingHigh(_Period, InpSwingLookback, InpStructuralSwingMinBars, current_processing_shift + 1); //
            PriceZone sweep_bear_info;
            if(prev_high.isValid && CheckAndGetBearishLiquiditySweep(_Period, prev_high, InpSweepMinSpikePoints, InpSweepCloseBackCandles, sweep_bear_info, current_processing_shift)) { //
                DrawLiquiditySweepMarker(_Period, sweep_bear_info, prev_high, false, InpBearishLSColor, InpArrowBearishSweepCode); //
            }
        }
    }
    ChartRedraw(); // Redraw once after all updates in the loop
    return(rates_total);
}
//+------------------------------------------------------------------+
//| Deinitialization function                                        |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
    // Delete objects if indicator is removed, chart closed, parameters changed, or recompiled
    if (reason == REASON_REMOVE || reason == REASON_CHARTCLOSE || 
        reason == REASON_PARAMETERS || reason == REASON_RECOMPILE ||
        reason == REASON_TEMPLATE ) { // Added REASON_TEMPLATE
        DeleteAllIndicatorObjects();
        ChartRedraw();
    }
    Comment(""); 
}
//+------------------------------------------------------------------+