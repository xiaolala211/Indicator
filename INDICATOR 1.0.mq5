//+------------------------------------------------------------------+
//| SMC_Visualizer_v2.0.mq5 - Part 3/N                               |
//| Input Parameters (with Tooltips)                                 |
//+------------------------------------------------------------------+

input group "--- General Settings ---"; // Group for general behavior
input int    InpMaxBarsToCalculate = 2000; // Max history bars to analyze (0 = All visible). Reduces load on startup.
input int    InpDeleteObjectsOlderThanNBars = 500; // Auto delete objects anchored on bars older than X bars (0 = disabled). Keeps chart clean.
input string InpObjectPrefix = "SMC_V2_"; // Prefix for all indicator objects. Avoids conflicts with other indicators.

input group "═══ Order Blocks (OB) ═══"; // Group for Order Blocks
input bool   InpDrawOrderBlocks = true;          // Draw Order Blocks?
input int    InpOrderBlockLookbackPeriod = 50;   // Lookback period (bars) for finding OBs.
input double InpMinMoveAfterOBFactor = 1.0;      // Minimum impulse move size relative to OB candle body/range (e.g., 1.0 = impulse must be >= OB size).
input int    InpMinImpulseCandles = 1;           // Minimum number of consecutive impulse candles required after the OB.
input bool   InpOBCheckDisplacement = true;      // Require impulse candle(s) to close beyond the high/low of the OB candle?
input bool   InpOBShowMitigated = true;          // Continue drawing OBs even after they have been mitigated?
input int    InpOBExtendBars = 50;               // Extend OB drawing X bars into the future from the current bar.
input bool   InpOBShowLabels = true;             // Show text labels (e.g., 'Bull OB') on Order Blocks?

input group "--- OB Visuals: Unmitigated ---";
input color  InpBullishOBColor = clrDeepSkyBlue;   // | Color (Fill) - Unmitigated Bullish OB
input color  InpBearishOBColor = clrLightCoral;    // | Color (Fill) - Unmitigated Bearish OB
input color  InpBullishOBBorderColor = clrBlue;    // | Color (Border) - Unmitigated Bullish OB
input color  InpBearishOBBorderColor = clrRed;     // | Color (Border) - Unmitigated Bearish OB
input ENUM_LINE_STYLE InpOB_Style = STYLE_SOLID;   // | Style (Border) - Unmitigated OB
input int    InpOB_Width = 1;                    // | Width (Border) - Unmitigated OB
input bool   InpOB_Fill = true;                    // | Fill Background? - Unmitigated OB

input group "--- OB Visuals: Mitigated ---";
input color  InpMitigatedOBColor = clrGray;        // | Color (Fill) - Mitigated OB
input color  InpMitigatedOBBorderColor = clrDimGray; // | Color (Border) - Mitigated OB
input ENUM_LINE_STYLE InpMitigatedOB_Style = STYLE_DOT; // | Style (Border) - Mitigated OB
input int    InpMitigatedOB_Width = 1;             // | Width (Border) - Mitigated OB
input bool   InpMitigatedOB_Fill = false;          // | Fill Background? - Mitigated OB

input group "═══ Fair Value Gaps (FVG) ═══"; // Group for FVGs
input bool   InpDrawFairValueGaps = true;        // Draw Fair Value Gaps?
input int    InpFVGLookbackPeriod = 50;          // Lookback period (bars) for finding FVGs.
input double InpMinFVGSizePoints = 10;           // Minimum FVG size in points (0 = disabled).
input bool   InpFVGShowMitigated = true;         // Continue drawing FVGs even after they have been mitigated?
input double InpFVGMitigationLevel = 0.5;        // Mitigation level (0.0-1.0). 0.5=50% fill, 1.0=full fill. Zone changes style when price reaches this level.
input int    InpFVGExtendBars = 50;              // Extend FVG drawing X bars into the future from the current bar.
input bool   InpFVGShowLabels = true;            // Show text labels (e.g., 'Bull FVG') on FVGs?

input group "--- FVG Visuals: Unmitigated ---";
input color  InpBullishFVGColor = clrLightSkyBlue; // | Color (Fill) - Unmitigated Bullish FVG
input color  InpBearishFVGColor = clrPink;         // | Color (Fill) - Unmitigated Bearish FVG
input color  InpBullishFVGBorderColor = clrCornflowerBlue; // | Color (Border) - Unmitigated Bullish FVG
input color  InpBearishFVGBorderColor = clrHotPink; // | Color (Border) - Unmitigated Bearish FVG
input ENUM_LINE_STYLE InpFVG_Style = STYLE_SOLID;  // | Style (Border) - Unmitigated FVG
input int    InpFVG_Width = 1;                   // | Width (Border) - Unmitigated FVG
input bool   InpFVG_Fill = true;                   // | Fill Background? - Unmitigated FVG

input group "--- FVG Visuals: Mitigated ---";
input color  InpMitigatedFVGColor = clrLightGray;  // | Color (Fill) - Mitigated FVG
input color  InpMitigatedFVGBorderColor = clrSilver; // | Color (Border) - Mitigated FVG
input ENUM_LINE_STYLE InpMitigatedFVG_Style = STYLE_DOT; // | Style (Border) - Mitigated FVG
input int    InpMitigatedFVG_Width = 1;            // | Width (Border) - Mitigated FVG
input bool   InpMitigatedFVG_Fill = false;         // | Fill Background? - Mitigated FVG

input group "═══ Liquidity & Structure ═══"; // Group for Liquidity and Structure
input bool   InpDrawLiquiditySweeps = true;      // Draw Liquidity Sweeps (LS)? Arrows marking highs/lows that were taken.
input double InpSweepMinSpikePoints = 5;         // | Minimum spike size in points beyond the swept high/low for LS.
input int    InpSweepCloseBackCandles = 1;       // | Maximum candles allowed for price to close back within the swept range for LS.
input bool   InpDrawStructure = true;            // Draw Structure Breaks (BOS/CHoCH)? Lines marking structural breaks.
input int    InpSwingLookback = 15;              // | Lookback period (bars) for identifying swing points used in structure analysis.
input int    InpStructuralSwingMinBars = 3;      // | Minimum bars required on each side for a candle to be considered a swing point (N).
input bool   InpStructureRequiresSweep = true;   // | Require a liquidity sweep to occur before confirming a BOS/CHoCH?

input group "--- LS & Structure Visuals ---";
input color  InpBullishLSColor = clrLimeGreen;     // | Color - Bullish Sweep Arrow
input color  InpBearishLSColor = clrOrangeRed;     // | Color - Bearish Sweep Arrow
input int    InpArrowBullishSweepCode = 241;       // | Arrow Code (Wingdings Font) - Bullish Sweep
input int    InpArrowBearishSweepCode = 242;       // | Arrow Code (Wingdings Font) - Bearish Sweep
input color  InpBOSColor = clrGreen;               // | Color - BOS Line/Label
input color  InpCHoCHColor = clrMagenta;           // | Color - CHoCH Line/Label
input ENUM_LINE_STYLE InpStructureLineStyle = STYLE_DASHDOT; // | Style - Structure Lines (BOS/CHoCH)
input int    InpStructureLineWidth = 1;          // | Width - Structure Lines
input bool   InpStructureShowLabels = true;      // | Show Labels (BOS/CHoCH) on structure lines?

input group "═══ Alerts ═══"; // Group for Alerts
input bool   InpEnableAlerts = false;              // Enable Alerts?
input bool   InpAlertOnOB = true;                  // | Alert on new Order Block detection?
input bool   InpAlertOnFVG = true;                 // | Alert on new Fair Value Gap detection?
input bool   InpAlertOnLS = true;                  // | Alert on new Liquidity Sweep detection?
input bool   InpAlertOnStructure = true;         // | Alert on new BOS/CHoCH detection?
input bool   InpAlertOnlyUnmitigated = true;     // | Alert only for newly detected unmitigated zones/events?
input ENUM_ALERT_TYPE InpAlertType = ALERT_MT5;    // | Alert Delivery Method (MT5 Popup, Push Notification, Email). Combine using '|' e.g., 1|2 for MT5+Push.
input int    InpAlertMaxPerBar = 1;              // | Max alerts of each type (OB, FVG, LS, Structure) per bar (0=unlimited). Prevents alert spam.

input group "═══ Dashboard ═══"; // Group for On-Screen Dashboard
input bool   InpShowDashboard = true;              // Show On-Screen Dashboard?
input ENUM_BASE_CORNER InpDashboardCorner = CORNER_TOP_LEFT; // | Corner for Dashboard placement.
input int    InpDashboardXOffset = 10;             // | X Offset (pixels) from the corner.
input int    InpDashboardYOffset = 20;             // | Y Offset (pixels) from the corner.
input color  InpDashboardTextColor = clrWhite;     // | Text Color for the dashboard.
input int    InpDashboardFontSize = 8;             // | Font Size for the dashboard text.
input color  InpDashboardBgColor = clrBlack;       // | Background Color for the dashboard.
input uint   InpDashboardUpdateFreqSecs = 5;     // | How often to update the dashboard content (seconds).


enum ENUM_ZONE_TYPE
{
   ZONE_TYPE_OB_BULL,
   ZONE_TYPE_OB_BEAR,
   ZONE_TYPE_FVG_BULL,
   ZONE_TYPE_FVG_BEAR
};

enum ENUM_ZONE_STATUS
{
   ZONE_STATUS_UNMITIGATED,
   ZONE_STATUS_MITIGATED_50, // Mitigated at 50%
   ZONE_STATUS_MITIGATED_FULL // Fully mitigated or invalidated
};

enum ENUM_STRUCTURE_TYPE
{
   STRUCTURE_NONE,
   STRUCTURE_BOS_BULL, // Break of Structure (High)
   STRUCTURE_BOS_BEAR, // Break of Structure (Low)
   STRUCTURE_CHoCH_BULL, // Change of Character (High)
   STRUCTURE_CHoCH_BEAR  // Change of Character (Low)
};

enum ENUM_ALERT_TYPE
{
   ALERT_NONE = 0,       // No alerts
   ALERT_MT5 = 1,        // MetaTrader 5 Alert window
   ALERT_PUSH = 2,       // Push Notification
   ALERT_EMAIL = 4,      // Email
   ALERT_ALL = 7         // All types (MT5 | PUSH | EMAIL)
};
// Combine types using bitwise OR, e.g., ALERT_MT5 | ALERT_PUSH

//+------------------------------------------------------------------+
//| Structures                                                       |
//+------------------------------------------------------------------+
// Structure to hold all relevant info about a detected price zone (OB/FVG)
class CPriceZone : public CObject
{
public:
   double            high;             // High price of the zone
   double            low;              // Low price of the zone
   datetime          time_start;       // Start time (anchor time) of the zone
   datetime          time_end;         // Calculated end time for drawing (based on extension)
   int               bar_index_anchor; // Shift of the anchor bar when detected
   ENUM_ZONE_TYPE    zone_type;        // Type of zone (Bull OB, Bear FVG, etc.)
   ENUM_ZONE_STATUS  status;           // Current status (Unmitigated, Mitigated 50%, Full)
   string            object_name;      // Name of the corresponding chart object
   bool              is_drawn;         // Flag if the object is currently drawn
   int               touch_count;      // How many times price touched the zone
   datetime          first_created;    // Timestamp when zone was first detected

                     CPriceZone();
   void              Reset();
   virtual int       Compare(const CObject *node, const int mode) const override;
};

CPriceZone::CPriceZone()
{
   Reset();
}

void CPriceZone::Reset()
{
   high = 0;
   low = 0;
   time_start = 0;
   time_end = 0;
   bar_index_anchor = -1;
   zone_type = ZONE_TYPE_OB_BULL; // Default, should be set properly
   status = ZONE_STATUS_UNMITIGATED;
   object_name = "";
   is_drawn = false;
   touch_count = 0;
   first_created = TimeCurrent();
}

// Comparison function for sorting/searching zones, e.g., by time
int CPriceZone::Compare(const CObject *node, const int mode) const
{
   const CPriceZone *other = (const CPriceZone*)node;
   // Compare by anchor time primarily
   if(this.time_start < other.time_start) return -1;
   if(this.time_start > other.time_start) return 1;
   // If times are equal, compare by type or other criteria if needed
   if(this.zone_type < other.zone_type) return -1;
   if(this.zone_type > other.zone_type) return 1;
   // If high/low are different, consider them different (prevents duplicates from slightly different detection points)
   if(this.high != other.high || this.low != other.low) return (this.high > other.high) ? 1 : -1;
   return 0; // Objects are considered equal based on this comparison
}

// Structure for Liquidity Sweeps & Structure Points (BOS/CHoCH)
class CStructurePoint : public CObject
{
public:
   datetime          time;             // Time of the event (sweep candle / break candle)
   double            price;            // Price level of the event (swept high/low, break level)
   int               bar_index;        // Shift of the event bar
   bool              is_bullish_sweep; // True for bullish sweep (low swept), false for bearish (high swept)
   bool              is_sweep;         // True if this is a liquidity sweep
   ENUM_STRUCTURE_TYPE structure_type; // Type of structure break (BOS/CHoCH)
   string            object_name;      // Name of the chart object (arrow/line)
   bool              is_drawn;

                     CStructurePoint();
   void              Reset();
   virtual int       Compare(const CObject *node, const int mode) const override;
};

CStructurePoint::CStructurePoint()
{
   Reset();
}

void CStructurePoint::Reset()
{
   time = 0;
   price = 0;
   bar_index = -1;
   is_bullish_sweep = false;
   is_sweep = false;
   structure_type = STRUCTURE_NONE;
   object_name = "";
   is_drawn = false;
}

int CStructurePoint::Compare(const CObject *node, const int mode) const
{
   const CStructurePoint *other = (const CStructurePoint*)node;
   if(this.time < other.time) return -1;
   if(this.time > other.time) return 1;
   // If time is same, compare by type
   if(this.is_sweep != other.is_sweep) return (this.is_sweep ? 1 : -1);
   if(this.structure_type != other.structure_type) return (this.structure_type > other.structure_type ? 1 : -1);
   // If still same, compare by price
   if(this.price != other.price) return (this.price > other.price ? 1 : -1);
   return 0;
}

// Global Variables
CSymbolInfo      symbolInfo;
string           indicator_short_name;
string           g_object_prefix; // Use global prefix from input
CArrayObj        g_zones;         // Array to manage CPriceZone objects
CArrayObj        g_structure_points; // Array to manage CStructurePoint objects
MqlRates         g_rates[];       // Global rates array to reduce CopyRates calls
datetime         g_last_dashboard_update = 0;
long             g_chart_id = 0;

// Alert throttling
int g_alert_count_ob_bar = 0;
int g_alert_count_fvg_bar = 0;
int g_alert_count_ls_bar = 0;
int g_alert_count_structure_bar = 0;
datetime g_last_alert_bar_time = 0;

//+------------------------------------------------------------------+
//| Helper Functions                                                 |
//+------------------------------------------------------------------+

// Function to generate unique object names
string GenerateObjectName(ENUM_ZONE_TYPE type, datetime time)
{
   return StringFormat("%s%s_%s", g_object_prefix, EnumToString(type), TimeToString(time, TIME_DATE | TIME_MINUTES | TIME_SECONDS));
}

string GenerateObjectName(ENUM_STRUCTURE_TYPE type, datetime time)
{
   return StringFormat("%s%s_%s", g_object_prefix, EnumToString(type), TimeToString(time, TIME_DATE | TIME_MINUTES | TIME_SECONDS));
}

string GenerateObjectName(bool is_bullish_sweep, datetime time)
{
   return StringFormat("%sLS_%s_%s", g_object_prefix, is_bullish_sweep ? "Bull" : "Bear", TimeToString(time, TIME_DATE | TIME_MINUTES | TIME_SECONDS));
}

// Function to send alerts
void SendAlert(string message, ENUM_ALERT_TYPE alert_type)
{
   if(!InpEnableAlerts) return;

   // Add Symbol and Timeframe context to the message
   string context = _Symbol + ", " + EnumToString(_Period) + ": ";
   message = context + message;

   if((alert_type & ALERT_MT5) != 0)
      Alert(message);
   if((alert_type & ALERT_PUSH) != 0)
      SendNotification(message);
   if((alert_type & ALERT_EMAIL) != 0)
      SendMail(IndicatorShortName() + ": Alert", message);
}

// Reset alert counts for a new bar
void ResetAlertCountsIfNeeded(datetime current_bar_time)
{
   if(current_bar_time != g_last_alert_bar_time)
   {
      g_alert_count_ob_bar = 0;
      g_alert_count_fvg_bar = 0;
      g_alert_count_ls_bar = 0;
      g_alert_count_structure_bar = 0;
      g_last_alert_bar_time = current_bar_time;
   }
}

// Check if alert limit is reached for the type
bool IsAlertLimitReached(string type)
{
   if(InpAlertMaxPerBar <= 0) return false; // Unlimited
   if(type == "OB" && g_alert_count_ob_bar >= InpAlertMaxPerBar) return true;
   if(type == "FVG" && g_alert_count_fvg_bar >= InpAlertMaxPerBar) return true;
   if(type == "LS" && g_alert_count_ls_bar >= InpAlertMaxPerBar) return true;
   if(type == "Structure" && g_alert_count_structure_bar >= InpAlertMaxPerBar) return true;
   return false;
}

// Increment alert count for the type
void IncrementAlertCount(string type)
{
   if(type == "OB") g_alert_count_ob_bar++;
   if(type == "FVG") g_alert_count_fvg_bar++;
   if(type == "LS") g_alert_count_ls_bar++;
   if(type == "Structure") g_alert_count_structure_bar++;
}

//+------------------------------------------------------------------+
//| Delete objects by prefix (Revised)                               |
//+------------------------------------------------------------------+
void DeleteObjectsByPrefix(const string prefix)
{
   // Iterate backwards as object count may change
   for(int i = ObjectsTotal(g_chart_id, 0, -1) - 1; i >= 0; i--)
   {
      string obj_name = ObjectName(g_chart_id, i, 0, -1);
      if(StringFind(obj_name, prefix) == 0) // If object name starts with the prefix
      {
         ObjectDelete(g_chart_id, obj_name);
      }
   }
}

//+------------------------------------------------------------------+
//| Helper to delete all objects managed by this indicator           |
//+------------------------------------------------------------------+
void DeleteAllIndicatorObjects()
{
   DeleteObjectsByPrefix(g_object_prefix); // Delete using the dynamic prefix
   // Also clear the management arrays
   g_zones.Clear();
   g_structure_points.Clear();
}

//+------------------------------------------------------------------+
//| Get bar shift by time (Revised for global rates array)           |
//+------------------------------------------------------------------+
int GetShiftByTime(datetime time_to_find)
{
   int rates_count = ArraySize(g_rates);
   if(rates_count <= 0) return -1;

   // Since g_rates is series (index 0 is current bar), we search from 0 upwards
   for(int i = 0; i < rates_count; i++)
   {
      if(g_rates[i].time == time_to_find)
      {
         return i; // Exact match
      }
      // If the time is between this bar's open and the next bar's open (or current time if it's the last bar)
      if(g_rates[i].time < time_to_find)
      {
         datetime next_bar_time = (i > 0) ? g_rates[i-1].time : TimeCurrent(); // Time of the newer bar
         if(time_to_find < next_bar_time)
         {
            return i; // Falls within this bar's duration
         }
      }
   }
   // Check if the time is newer than the current bar's time
   if(time_to_find > g_rates[0].time) return 0;

   return -1; // Not found
}

//+------------------------------------------------------------------+
//| Cleanup old objects based on anchor bar age (Revised)            |
//+------------------------------------------------------------------+
void CleanupOldObjects(int max_age_bars_ago)
{
   if (max_age_bars_ago <= 0) return; // Feature disabled

   bool changed = false;
   datetime oldest_allowed_time = 0;
   int rates_count = ArraySize(g_rates);
   if(rates_count > max_age_bars_ago)
   {
      // g_rates[max_age_bars_ago] is the bar 'max_age_bars_ago' shifts ago
      oldest_allowed_time = g_rates[max_age_bars_ago].time;
   }
   else
   {
      return; // Not enough history to determine age
   }

   // Clean Price Zones
   for(int i = g_zones.Total() - 1; i >= 0; i--)
   {
      CPriceZone *zone = g_zones.At(i);
      if(zone == NULL) continue;

      // Check if the zone's *start time* is older than the cutoff time
      if(zone.time_start < oldest_allowed_time)
      {
         if(zone.is_drawn) ObjectDelete(g_chart_id, zone.object_name);
         // Need to delete associated label too
         string label_name = zone.object_name + "_Label";
         ObjectDelete(g_chart_id, label_name);
         g_zones.Delete(i);
         changed = true;
      }
   }

   // Clean Structure Points
   for(int i = g_structure_points.Total() - 1; i >= 0; i--)
   {
      CStructurePoint *sp = g_structure_points.At(i);
      if(sp == NULL) continue;

      // Check if the structure point's time is older than the cutoff time
      if(sp.time < oldest_allowed_time)
      {
         if(sp.is_drawn) ObjectDelete(g_chart_id, sp.object_name);
         // Need to delete associated label too
         string label_name = sp.object_name + "_Label";
         ObjectDelete(g_chart_id, label_name);
         g_structure_points.Delete(i);
         changed = true;
      }
   }


}


//--- Drawing Functions --- 

// Draws or updates the rectangle object for a Price Zone (OB/FVG)
void DrawZoneObject(CPriceZone *zone)
{
   if(zone == NULL) return;

   // Determine if the zone should be drawn based on mitigation status and input settings
   bool is_mitigated = (zone.status != ZONE_STATUS_UNMITIGATED);
   bool is_ob = (zone.zone_type == ZONE_TYPE_OB_BULL || zone.zone_type == ZONE_TYPE_OB_BEAR);
   bool is_fvg = (zone.zone_type == ZONE_TYPE_FVG_BULL || zone.zone_type == ZONE_TYPE_FVG_BEAR);

   // Decide whether to draw or delete based on mitigation status and settings
   bool should_draw = true;
   if(is_mitigated) {
       if(is_ob && !InpOBShowMitigated) should_draw = false;
       if(is_fvg && !InpFVGShowMitigated) should_draw = false;
   }

   // Define object names
   string rect_name = zone.object_name;
   string label_name = rect_name + "_Label";

   // If the zone should not be drawn (e.g., mitigated and setting is off), delete existing objects
   if(!should_draw)
   {
      if(zone.is_drawn) {
          ObjectDelete(g_chart_id, rect_name);
          ObjectDelete(g_chart_id, label_name); // Delete label too
          zone.is_drawn = false;
      }
      return; // Stop further processing for this zone
   }

   // --- Determine Visual Properties --- 
   color fill_color, border_color;
   ENUM_LINE_STYLE style;
   int width;
   bool fill;

   switch(zone.zone_type)
   {
      case ZONE_TYPE_OB_BULL:
         fill_color = is_mitigated ? InpMitigatedOBColor : InpBullishOBColor;
         border_color = is_mitigated ? InpMitigatedOBBorderColor : InpBullishOBBorderColor;
         style = is_mitigated ? InpMitigatedOB_Style : InpOB_Style;
         width = is_mitigated ? InpMitigatedOB_Width : InpOB_Width;
         fill = is_mitigated ? InpMitigatedOB_Fill : InpOB_Fill;
         break;
      case ZONE_TYPE_OB_BEAR:
         fill_color = is_mitigated ? InpMitigatedOBColor : InpBearishOBColor;
         border_color = is_mitigated ? InpMitigatedOBBorderColor : InpBearishOBBorderColor;
         style = is_mitigated ? InpMitigatedOB_Style : InpOB_Style;
         width = is_mitigated ? InpMitigatedOB_Width : InpOB_Width;
         fill = is_mitigated ? InpMitigatedOB_Fill : InpOB_Fill;
         break;
      case ZONE_TYPE_FVG_BULL:
         fill_color = is_mitigated ? InpMitigatedFVGColor : InpBullishFVGColor;
         border_color = is_mitigated ? InpMitigatedFVGBorderColor : InpBullishFVGBorderColor;
         style = is_mitigated ? InpMitigatedFVG_Style : InpFVG_Style;
         width = is_mitigated ? InpMitigatedFVG_Width : InpFVG_Width;
         fill = is_mitigated ? InpMitigatedFVG_Fill : InpFVG_Fill;
         break;
      case ZONE_TYPE_FVG_BEAR:
         fill_color = is_mitigated ? InpMitigatedFVGColor : InpBearishFVGColor;
         border_color = is_mitigated ? InpMitigatedFVGBorderColor : InpBearishFVGBorderColor;
         style = is_mitigated ? InpMitigatedFVG_Style : InpFVG_Style;
         width = is_mitigated ? InpMitigatedFVG_Width : InpFVG_Width;
         fill = is_mitigated ? InpMitigatedFVG_Fill : InpFVG_Fill;
         break;
      default: // Should not happen
         return;
   }

   // --- Calculate End Time for Extension --- 
   int extend_bars = is_ob ? InpOBExtendBars : InpFVGExtendBars;
   datetime time_now = g_rates[0].time; // Current bar's open time from global array
   zone.time_end = time_now + PeriodSeconds() * extend_bars;

   // --- Create or Update Rectangle Object --- 
   if(ObjectFind(g_chart_id, rect_name) < 0)
   {
      // Create new object
      if(!ObjectCreate(g_chart_id, rect_name, OBJ_RECTANGLE, 0, zone.time_start, zone.high, zone.time_end, zone.low))
      {
         PrintFormat("Error creating zone object %s: %d", rect_name, GetLastError());
         return;
      }
      zone.is_drawn = true;
      // Set all properties for new object
      ObjectSetInteger(g_chart_id, rect_name, OBJPROP_COLOR, border_color);
      ObjectSetInteger(g_chart_id, rect_name, OBJPROP_STYLE, style);
      ObjectSetInteger(g_chart_id, rect_name, OBJPROP_WIDTH, width);
      ObjectSetInteger(g_chart_id, rect_name, OBJPROP_FILL, fill);
      if(fill) ObjectSetInteger(g_chart_id, rect_name, OBJPROP_BGCOLOR, fill_color);
      ObjectSetInteger(g_chart_id, rect_name, OBJPROP_BACK, true);
      ObjectSetInteger(g_chart_id, rect_name, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(g_chart_id, rect_name, OBJPROP_HIDDEN, false); // Ensure it's visible
   }
   else
   {
      // Update existing object - only update properties that might change
      ObjectSetInteger(g_chart_id, rect_name, OBJPROP_TIME, 1, zone.time_end); // Update end time
      ObjectSetInteger(g_chart_id, rect_name, OBJPROP_COLOR, border_color);   // Update border color (might change if mitigated)
      ObjectSetInteger(g_chart_id, rect_name, OBJPROP_STYLE, style);           // Update style (might change if mitigated)
      ObjectSetInteger(g_chart_id, rect_name, OBJPROP_WIDTH, width);           // Update width (might change if mitigated)
      ObjectSetInteger(g_chart_id, rect_name, OBJPROP_FILL, fill);             // Update fill property
      if(fill) ObjectSetInteger(g_chart_id, rect_name, OBJPROP_BGCOLOR, fill_color); // Update fill color if fill is enabled
      else ObjectSetInteger(g_chart_id, rect_name, OBJPROP_BGCOLOR, clrNONE); // Explicitly remove BG color if fill is false
      zone.is_drawn = true; // Ensure flag is set
   }

   // --- Tooltip --- 
   string status_str = EnumToString(zone.status);
   StringReplace(status_str, "ZONE_STATUS_", ""); // Make it shorter
   string tooltip = StringFormat("%s\n%s - %s\nH: %s L: %s\nStatus: %s",
                                EnumToString(zone.zone_type),
                                TimeToString(zone.time_start, TIME_DATE|TIME_MINUTES),
                                TimeToString(zone.time_end, TIME_DATE|TIME_MINUTES),
                                DoubleToString(zone.high, _Digits),
                                DoubleToString(zone.low, _Digits),
                                status_str);
   ObjectSetString(g_chart_id, rect_name, OBJPROP_TOOLTIP, tooltip);

   // --- Add/Update/Delete Label --- 
   bool show_label = is_ob ? InpOBShowLabels : InpFVGShowLabels;

   if(show_label)
   {
      string label_text = "";
      if(zone.zone_type == ZONE_TYPE_OB_BULL) label_text = "Bull OB";
      if(zone.zone_type == ZONE_TYPE_OB_BEAR) label_text = "Bear OB";
      if(zone.zone_type == ZONE_TYPE_FVG_BULL) label_text = "Bull FVG";
      if(zone.zone_type == ZONE_TYPE_FVG_BEAR) label_text = "Bear FVG";
      if(is_mitigated) label_text += " (M)"; // Add mitigated marker

      // Position label slightly below the zone, centered time-wise within the visible part
      datetime label_time = zone.time_start + PeriodSeconds() * 2; // Position near the start
      double label_price = zone.low - symbolInfo.Point() * 15; // Position below the zone

      if(ObjectFind(g_chart_id, label_name) < 0)
      {
         // Create new label
         if(!ObjectCreate(g_chart_id, label_name, OBJ_TEXT, 0, label_time, label_price))
         {
            PrintFormat("Error creating label object %s: %d", label_name, GetLastError());
         }
         else
         {
            // Set constant properties for new label
            ObjectSetInteger(g_chart_id, label_name, OBJPROP_FONTSIZE, 8);
            ObjectSetString(g_chart_id, label_name, OBJPROP_FONT, "Arial");
            ObjectSetInteger(g_chart_id, label_name, OBJPROP_ANCHOR, ANCHOR_LEFT_LOWER);
            ObjectSetInteger(g_chart_id, label_name, OBJPROP_SELECTABLE, false);
            ObjectSetInteger(g_chart_id, label_name, OBJPROP_BACK, false);
         }
      }
      // Update dynamic properties for existing or new label
      ObjectSetString(g_chart_id, label_name, OBJPROP_TEXT, label_text);
      ObjectSetInteger(g_chart_id, label_name, OBJPROP_TIME, 0, label_time);
      ObjectSetDouble(g_chart_id, label_name, OBJPROP_PRICE, 0, label_price);
      ObjectSetInteger(g_chart_id, label_name, OBJPROP_COLOR, border_color); // Match label color to border color
   }
   else
   {
      // Delete label if it exists and shouldn't be shown
      if(ObjectFind(g_chart_id, label_name) >= 0) ObjectDelete(g_chart_id, label_name);
   }
}

// Draws or updates the object for a Structure Point (Sweep/BOS/CHoCH)
void DrawStructurePointObject(CStructurePoint *sp)
{
   if(sp == NULL) return;

   string obj_name = sp.object_name;
   string label_name = obj_name + "_Label";
   bool should_draw = true;

   // Check if this type of object should be drawn based on inputs
   if(sp.is_sweep && !InpDrawLiquiditySweeps) should_draw = false;
   if(sp.structure_type != STRUCTURE_NONE && !InpDrawStructure) should_draw = false;

   // If shouldn't draw, delete existing objects
   if(!should_draw)
   {
      if(sp.is_drawn) {
         ObjectDelete(g_chart_id, obj_name);
         ObjectDelete(g_chart_id, label_name);
         sp.is_drawn = false;
      }
      return;
   }

   // --- Draw Liquidity Sweep Arrow --- 
   if(sp.is_sweep)
   {
      color sweep_color = sp.is_bullish_sweep ? InpBullishLSColor : InpBearishLSColor;
      int arrow_code = sp.is_bullish_sweep ? InpArrowBullishSweepCode : InpArrowBearishSweepCode;
      // Position arrow slightly above/below the high/low of the sweep candle
      double arrow_price;
      MqlRates sweep_candle;
      if(CopyRates(_Symbol, _Period, sp.time, 1, sweep_candle) > 0) {
          arrow_price = sp.is_bullish_sweep ? sweep_candle[0].low : sweep_candle[0].high;
      } else {
          arrow_price = sp.price; // Fallback to stored price if rate copy fails
      }
      double price_offset = symbolInfo.Point() * 25; // Offset arrow slightly further

      if(sp.is_bullish_sweep) arrow_price -= price_offset; // Below the low
      else arrow_price += price_offset; // Above the high

      if(ObjectFind(g_chart_id, obj_name) < 0)
      {
         // Create new arrow
         if(!ObjectCreate(g_chart_id, obj_name, OBJ_ARROW, 0, sp.time, arrow_price))
         {
            PrintFormat("Error creating LS arrow object %s: %d", obj_name, GetLastError());
            return;
         }
         sp.is_drawn = true;
         // Set properties for new arrow
         ObjectSetInteger(g_chart_id, obj_name, OBJPROP_ARROWCODE, arrow_code);
         ObjectSetInteger(g_chart_id, obj_name, OBJPROP_COLOR, sweep_color);
         ObjectSetInteger(g_chart_id, obj_name, OBJPROP_WIDTH, 1);
         ObjectSetInteger(g_chart_id, obj_name, OBJPROP_SELECTABLE, false);
         ObjectSetInteger(g_chart_id, obj_name, OBJPROP_BACK, false);
      }
      else
      {
         // Update existing arrow (only position might need minor adjustment if logic changes)
         ObjectSetInteger(g_chart_id, obj_name, OBJPROP_TIME, 0, sp.time);
         ObjectSetDouble(g_chart_id, obj_name, OBJPROP_PRICE, 0, arrow_price);
         ObjectSetInteger(g_chart_id, obj_name, OBJPROP_COLOR, sweep_color); // Ensure color is correct
         sp.is_drawn = true; // Ensure flag is set
      }
      // Tooltip
      string tooltip = StringFormat("Sweep (%s)\nPrice: %s\nBar: %s (%d ago)",
                                sp.is_bullish_sweep ? "Bullish" : "Bearish",
                                DoubleToString(sp.price, _Digits), // Show the actual swept price level
                                TimeToString(sp.time, TIME_DATE|TIME_MINUTES),
                                sp.bar_index);
      ObjectSetString(g_chart_id, obj_name, OBJPROP_TOOLTIP, tooltip);
      // No separate label for sweeps currently
      ObjectDelete(g_chart_id, label_name); // Ensure no label exists
   }
   // --- Draw Structure Line (BOS/CHoCH) --- 
   else if(sp.structure_type != STRUCTURE_NONE)
   {
      color line_color;
      string label_text;
      switch(sp.structure_type)
      {
         case STRUCTURE_BOS_BULL: line_color = InpBOSColor; label_text = "BOS"; break;
         case STRUCTURE_BOS_BEAR: line_color = InpBOSColor; label_text = "BOS"; break;
         case STRUCTURE_CHoCH_BULL: line_color = InpCHoCHColor; label_text = "CHoCH"; break;
         case STRUCTURE_CHoCH_BEAR: line_color = InpCHoCHColor; label_text = "CHoCH"; break;
         default: return;
      }

      // Draw a horizontal line segment starting from the break bar
      datetime time_start = sp.time;
      datetime time_end = g_rates[0].time + PeriodSeconds() * 10; // Extend slightly into the future

      if(ObjectFind(g_chart_id, obj_name) < 0)
      {
         // Create new trendline object to represent the horizontal break level
         if(!ObjectCreate(g_chart_id, obj_name, OBJ_TREND, 0, time_start, sp.price, time_end, sp.price))
         {
            PrintFormat("Error creating structure line object %s: %d", obj_name, GetLastError());
            return;
         }
         sp.is_drawn = true;
         // Set properties for new line
         ObjectSetInteger(g_chart_id, obj_name, OBJPROP_COLOR, line_color);
         ObjectSetInteger(g_chart_id, obj_name, OBJPROP_STYLE, InpStructureLineStyle);
         ObjectSetInteger(g_chart_id, obj_name, OBJPROP_WIDTH, InpStructureLineWidth);
         ObjectSetInteger(g_chart_id, obj_name, OBJPROP_SELECTABLE, false);
         ObjectSetInteger(g_chart_id, obj_name, OBJPROP_BACK, true);
         ObjectSetInteger(g_chart_id, obj_name, OBJPROP_RAY_RIGHT, false); // Don't extend infinitely
      }
      else
      {
         // Update existing line
         ObjectSetInteger(g_chart_id, obj_name, OBJPROP_TIME, 0, time_start);
         ObjectSetDouble(g_chart_id, obj_name, OBJPROP_PRICE, 0, sp.price);
         ObjectSetInteger(g_chart_id, obj_name, OBJPROP_TIME, 1, time_end);
         ObjectSetDouble(g_chart_id, obj_name, OBJPROP_PRICE, 1, sp.price);
         ObjectSetInteger(g_chart_id, obj_name, OBJPROP_COLOR, line_color);
         ObjectSetInteger(g_chart_id, obj_name, OBJPROP_STYLE, InpStructureLineStyle);
         ObjectSetInteger(g_chart_id, obj_name, OBJPROP_WIDTH, InpStructureLineWidth);
         sp.is_drawn = true; // Ensure flag is set
      }

      // Tooltip
      string tooltip = StringFormat("%s @ %s\nBar: %s (%d ago)",
                                label_text,
                                DoubleToString(sp.price, _Digits),
                                TimeToString(sp.time, TIME_DATE|TIME_MINUTES),
                                sp.bar_index);
      ObjectSetString(g_chart_id, obj_name, OBJPROP_TOOLTIP, tooltip);

      // --- Add/Update/Delete Label --- 
      if(InpStructureShowLabels)
      {
         datetime label_time = sp.time + PeriodSeconds() * 2; // Position label slightly after the break
         double label_price = sp.price;
         // Adjust anchor based on whether it's breaking high or low
         ENUM_ANCHOR_POINT anchor = (sp.structure_type == STRUCTURE_BOS_BULL || sp.structure_type == STRUCTURE_CHoCH_BULL) ? ANCHOR_LEFT_UPPER : ANCHOR_LEFT_LOWER;

         if(ObjectFind(g_chart_id, label_name) < 0)
         {
            // Create new label
            if(!ObjectCreate(g_chart_id, label_name, OBJ_TEXT, 0, label_time, label_price))
            {
               PrintFormat("Error creating structure label object %s: %d", label_name, GetLastError());
            }
            else
            {
               // Set constant properties
               ObjectSetInteger(g_chart_id, label_name, OBJPROP_FONTSIZE, 9);
               ObjectSetString(g_chart_id, label_name, OBJPROP_FONT, "Arial");
               ObjectSetInteger(g_chart_id, label_name, OBJPROP_SELECTABLE, false);
               ObjectSetInteger(g_chart_id, label_name, OBJPROP_BACK, false);
            }
         }
         // Update dynamic properties
         ObjectSetString(g_chart_id, label_name, OBJPROP_TEXT, label_text);
         ObjectSetInteger(g_chart_id, label_name, OBJPROP_TIME, 0, label_time);
         ObjectSetDouble(g_chart_id, label_name, OBJPROP_PRICE, 0, label_price);
         ObjectSetInteger(g_chart_id, label_name, OBJPROP_COLOR, line_color);
         ObjectSetInteger(g_chart_id, label_name, OBJPROP_ANCHOR, anchor);
      }
      else
      {
         // Delete label if it exists and shouldn't be shown
         if(ObjectFind(g_chart_id, label_name) >= 0) ObjectDelete(g_chart_id, label_name);
      }
   }
}

//--- Detection Functions --- 

// Optimized function to find the last significant swing high within a lookback range
// Returns a temporary PriceZone struct (not a class pointer) containing swing info
// Uses the global g_rates array
// 'start_shift' is the newest bar (lowest index in g_rates) to start checking FROM (exclusive)
// e.g., if checking for swing high before bar at shift 5, call with start_shift = 5
struct SwingPointInfo // Use a simple struct for return value, not a full CPriceZone object
{
   double            price;      // High price for swing high, Low price for swing low
   int               bar_index;  // Shift of the swing bar
   datetime          time;       // Time of the swing bar
   bool              isValid;    // Was a valid swing found?

   void SwingPointInfo() { Reset(); }
   void Reset() { price = 0; bar_index = -1; time = 0; isValid = false; }
};

SwingPointInfo GetLastSignificantSwingHighOptimized(const int lookback_range, const int N, const int start_shift)
{
   SwingPointInfo swing_high;
   if (N < 1) return swing_high; // N must be at least 1
   int rates_count = ArraySize(g_rates);

   // Define the loop range based on start_shift and lookback_range
   // candidate_shift is the index in g_rates we are checking if it's a swing high
   // It must be older than start_shift, so candidate_shift > start_shift
   // The oldest bar to check is start_shift + lookback_range
   int oldest_check_shift = MathMin(rates_count - 1 - N, start_shift + lookback_range + N);
   int newest_check_shift = start_shift + N; // Need N bars to the left (newer)

   // Iterate from newer potential swings to older ones within the lookback range
   for (int candidate_shift = newest_check_shift; candidate_shift <= oldest_check_shift; candidate_shift++)
   {
      // Basic boundary checks
      if (candidate_shift < N || candidate_shift + N >= rates_count) continue;

      bool is_swing_high = true;
      double candidate_high_price = g_rates[candidate_shift].high;

      // Check N bars to the right (older candles, index > candidate_shift)
      for (int j = 1; j <= N; j++) {
         if (g_rates[candidate_shift + j].high >= candidate_high_price) {
            is_swing_high = false; break;
         }
      }
      if (!is_swing_high) continue;

      // Check N bars to the left (newer candles, index < candidate_shift)
      for (int j = 1; j <= N; j++) {
         // Use > for strict high (must be uniquely highest among left neighbors)
         if (g_rates[candidate_shift - j].high > candidate_high_price) {
            is_swing_high = false; break;
         }
      }

      if (is_swing_high) {
         swing_high.price = candidate_high_price;
         swing_high.bar_index = candidate_shift; // Store the shift
         swing_high.time = g_rates[candidate_shift].time; // Store the time
         swing_high.isValid = true;
         return swing_high; // Return the *most recent* valid swing high found within the range
      }
   }
   return swing_high; // Return empty struct if none found
}

// Optimized function to find the last significant swing low
SwingPointInfo GetLastSignificantSwingLowOptimized(const int lookback_range, const int N, const int start_shift)
{
   SwingPointInfo swing_low;
   if (N < 1) return swing_low;
   int rates_count = ArraySize(g_rates);

   int oldest_check_shift = MathMin(rates_count - 1 - N, start_shift + lookback_range + N);
   int newest_check_shift = start_shift + N;

   for (int candidate_shift = newest_check_shift; candidate_shift <= oldest_check_shift; candidate_shift++)
   {
      if (candidate_shift < N || candidate_shift + N >= rates_count) continue;

      bool is_swing_low = true;
      double candidate_low_price = g_rates[candidate_shift].low;

      // Check N bars to the right (older)
      for (int j = 1; j <= N; j++) {
         if (g_rates[candidate_shift + j].low <= candidate_low_price) {
            is_swing_low = false; break;
         }
      }
      if (!is_swing_low) continue;

      // Check N bars to the left (newer)
      // Use < for strict low
      for (int j = 1; j <= N; j++) {
         if (g_rates[candidate_shift - j].low < candidate_low_price) {
            is_swing_low = false; break;
         }
      }

      if (is_swing_low) {
         swing_low.price = candidate_low_price;
         swing_low.bar_index = candidate_shift;
         swing_low.time = g_rates[candidate_shift].time;
         swing_low.isValid = true;
         return swing_low; // Return the most recent valid swing low
      }
   }
   return swing_low;
}

// Function to check and update zone mitigation status based on price action at 'current_shift'
void CheckZoneMitigation(CPriceZone *zone, const int current_shift)
{
   // Don't check if zone is already fully mitigated or if the current bar is the anchor bar or older
   if(zone == NULL || zone.status == ZONE_STATUS_MITIGATED_FULL || current_shift >= zone.bar_index_anchor) return;

   // Get price data for the current bar being checked
   double high_price = g_rates[current_shift].high;
   double low_price = g_rates[current_shift].low;
   double close_price = g_rates[current_shift].close; // Needed for some mitigation types

   // Calculate mitigation levels
   double zone_mid_price = zone.low + (zone.high - zone.low) * 0.5;
   double fvg_mitigation_price = 0;
   if(zone.zone_type == ZONE_TYPE_FVG_BULL || zone.zone_type == ZONE_TYPE_FVG_BEAR)
   {
       // Ensure mitigation level is valid (0 to 1)
       double valid_mit_level = MathMax(0.0, MathMin(1.0, InpFVGMitigationLevel));
       if(zone.zone_type == ZONE_TYPE_FVG_BULL) {
           fvg_mitigation_price = zone.low + (zone.high - zone.low) * valid_mit_level;
       } else { // Bear FVG
           fvg_mitigation_price = zone.high - (zone.high - zone.low) * valid_mit_level;
       }
   }

   bool touched = false;
   bool mitigated_target = false; // Reached the defined mitigation level (e.g., 50% FVG)
   bool mitigated_full = false;   // Fully filled/invalidated

   switch(zone.zone_type)
   {
      case ZONE_TYPE_OB_BULL:
         // OB is considered touched if low goes into the zone
         if(low_price <= zone.high && high_price >= zone.low) touched = true;
         // OB is considered fully mitigated if low breaks below the OB low
         if(low_price < zone.low) mitigated_full = true;
         // Simple touch mitigation: if touched, consider it fully mitigated for OBs
         if(touched) mitigated_target = true; 
         break;

      case ZONE_TYPE_OB_BEAR:
         if(high_price >= zone.low && low_price <= zone.high) touched = true;
         // Fully mitigated if high breaks above the OB high
         if(high_price > zone.high) mitigated_full = true;
         if(touched) mitigated_target = true;
         break;

      case ZONE_TYPE_FVG_BULL:
         // Touched if low enters the gap
         if(low_price <= zone.high && high_price >= zone.low) touched = true;
         // Reached target mitigation level if low reaches or passes the calculated level
         if(low_price <= fvg_mitigation_price) mitigated_target = true;
         // Fully mitigated if low reaches or passes the bottom of the gap (FVG low)
         if(low_price <= zone.low) mitigated_full = true;
         break;

      case ZONE_TYPE_FVG_BEAR:
         if(high_price >= zone.low && low_price <= zone.high) touched = true;
         // Reached target mitigation level if high reaches or passes the calculated level
         if(high_price >= fvg_mitigation_price) mitigated_target = true;
         // Fully mitigated if high reaches or passes the top of the gap (FVG high)
         if(high_price >= zone.high) mitigated_full = true;
         break;
   }

   if(touched) zone.touch_count++;

   // Update status based on findings
   if(mitigated_full)
   {
      zone.status = ZONE_STATUS_MITIGATED_FULL;
   }
   else if(mitigated_target && zone.status == ZONE_STATUS_UNMITIGATED)
   {
      // For FVGs, use MITIGATED_50 if level is between 0 and 1 (exclusive)
      if((zone.zone_type == ZONE_TYPE_FVG_BULL || zone.zone_type == ZONE_TYPE_FVG_BEAR) && InpFVGMitigationLevel > 0.0 && InpFVGMitigationLevel < 1.0)
      {
         zone.status = ZONE_STATUS_MITIGATED_50;
      }
      else // For OBs or FVGs with 0% or 100% mitigation level, any target mitigation counts as full
      {
          zone.status = ZONE_STATUS_MITIGATED_FULL;
      }
   }
   // If only touched but not mitigated to target level, status remains UNMITIGATED (but touch_count increases)
}


// Optimized function to find the last valid Order Block (OB) before a given shift
// Returns a CPriceZone object pointer if found, otherwise NULL
// Uses the global g_rates array
CPriceZone* FindOrderBlockOptimized(const int start_shift)
{
   if(!InpDrawOrderBlocks) return NULL;
   int rates_count = ArraySize(g_rates);
   int lookback = InpOrderBlockLookbackPeriod;

   // Iterate backwards from the bar *before* start_shift
   for(int i = start_shift + 1; i < MathMin(rates_count, start_shift + 1 + lookback); i++)
   {
      // Ensure we have enough bars for displacement check
      if(i < InpMinImpulseCandles) continue;

      // --- Check for Bullish OB (Last down candle before strong up move) ---
      // OB Candle (i) must be bearish (close < open)
      if(g_rates[i].close < g_rates[i].open)
      {
         bool strong_up_move = true;
         // Check subsequent candles (i-1, i-2, ... i-InpMinImpulseCandles) for bullish impulse
         for(int k = 1; k <= InpMinImpulseCandles; k++)
         {
            if(g_rates[i-k].close <= g_rates[i-k].open) // Must be bullish candles
            {
               strong_up_move = false; break;
            }
         }

         if(strong_up_move)
         {
            // Check displacement: The last impulse candle (i-InpMinImpulseCandles) must close above the OB candle's high
            bool displacement_met = !InpOBCheckDisplacement || (g_rates[i-InpMinImpulseCandles].close > g_rates[i].high);

            // Check minimum move size: The total range of the impulse move vs OB range
            double impulse_high = g_rates[i-InpMinImpulseCandles].high;
            double impulse_low = g_rates[i-1].low; // Low of the first impulse candle
            double impulse_range = impulse_high - impulse_low;
            double ob_range = g_rates[i].high - g_rates[i].low;
            if (ob_range <= 0) ob_range = symbolInfo.Point(); // Avoid division by zero
            bool min_move_met = (impulse_range / ob_range) >= InpMinMoveAfterOBFactor;

            if(displacement_met && min_move_met)
            {
               // Found a Bullish OB
               CPriceZone *zone = new CPriceZone();
               zone.zone_type = ZONE_TYPE_OB_BULL;
               zone.high = g_rates[i].high;
               zone.low = g_rates[i].low;
               zone.time_start = g_rates[i].time;
               zone.bar_index_anchor = i;
               zone.object_name = GenerateObjectName(zone.zone_type, zone.time_start);
               // Check if this exact zone already exists (by time and type)
               if(g_zones.Search(zone) < 0) {
                   return zone; // Return the new zone object
               } else {
                   delete zone; // Duplicate found, delete the new one
                   // Continue searching for older OBs if needed, or just return NULL if only the latest is desired
                   // For simplicity, let's assume we only want the *most recent* valid one relative to start_shift
                   return NULL; // Or break; depending on desired behavior
               }
            }
         }
      }

      // --- Check for Bearish OB (Last up candle before strong down move) ---
      // OB Candle (i) must be bullish (close > open)
      if(g_rates[i].close > g_rates[i].open)
      {
         bool strong_down_move = true;
         // Check subsequent candles (i-1, i-2, ... i-InpMinImpulseCandles) for bearish impulse
         for(int k = 1; k <= InpMinImpulseCandles; k++)
         {
            if(g_rates[i-k].close >= g_rates[i-k].open) // Must be bearish candles
            {
               strong_down_move = false; break;
            }
         }

         if(strong_down_move)
         {
            // Check displacement: The last impulse candle (i-InpMinImpulseCandles) must close below the OB candle's low
            bool displacement_met = !InpOBCheckDisplacement || (g_rates[i-InpMinImpulseCandles].close < g_rates[i].low);

            // Check minimum move size
            double impulse_low = g_rates[i-InpMinImpulseCandles].low;
            double impulse_high = g_rates[i-1].high; // High of the first impulse candle
            double impulse_range = impulse_high - impulse_low;
            double ob_range = g_rates[i].high - g_rates[i].low;
            if (ob_range <= 0) ob_range = symbolInfo.Point();
            bool min_move_met = (impulse_range / ob_range) >= InpMinMoveAfterOBFactor;

            if(displacement_met && min_move_met)
            {
               // Found a Bearish OB
               CPriceZone *zone = new CPriceZone();
               zone.zone_type = ZONE_TYPE_OB_BEAR;
               zone.high = g_rates[i].high;
               zone.low = g_rates[i].low;
               zone.time_start = g_rates[i].time;
               zone.bar_index_anchor = i;
               zone.object_name = GenerateObjectName(zone.zone_type, zone.time_start);
               if(g_zones.Search(zone) < 0) {
                   return zone;
               } else {
                   delete zone;
                   return NULL; // Found duplicate
               }
            }
         }
      }
   }

   return NULL; // No OB found within lookback
}

// Optimized function to find the last valid Fair Value Gap (FVG) before a given shift
// Returns a CPriceZone object pointer if found, otherwise NULL
// Uses the global g_rates array
CPriceZone* FindFairValueGapOptimized(const int start_shift)
{
   if(!InpDrawFairValueGaps) return NULL;
   int rates_count = ArraySize(g_rates);
   int lookback = InpFVGLookbackPeriod;

   // FVG requires 3 candles. Check starts from the bar *before* start_shift.
   // The pattern involves candles at shifts: i+2, i+1, i
   // We iterate i from start_shift+1 backwards
   for(int i = start_shift + 1; i < MathMin(rates_count - 2, start_shift + 1 + lookback); i++)
   {
      // Candle indices: prev_prev = i+2, prev = i+1, current = i
      double prev_prev_high = g_rates[i+2].high;
      double prev_prev_low = g_rates[i+2].low;
      double prev_high = g_rates[i+1].high;
      double prev_low = g_rates[i+1].low;
      double current_high = g_rates[i].high;
      double current_low = g_rates[i].low;

      // --- Check for Bullish FVG (Gap between prev_prev_high and current_low) ---
      // Condition: current_low > prev_prev_high
      if(current_low > prev_prev_high)
      {
         double fvg_high = current_low;
         double fvg_low = prev_prev_high;
         double fvg_size_points = (fvg_high - fvg_low) / symbolInfo.Point();

         // Check minimum size
         if(fvg_size_points >= InpMinFVGSizePoints)
         {
            // Found a Bullish FVG
            CPriceZone *zone = new CPriceZone();
            zone.zone_type = ZONE_TYPE_FVG_BULL;
            zone.high = fvg_high;
            zone.low = fvg_low;
            // Anchor time is the middle candle's time (prev)
            zone.time_start = g_rates[i+1].time;
            zone.bar_index_anchor = i+1;
            zone.object_name = GenerateObjectName(zone.zone_type, zone.time_start);
            if(g_zones.Search(zone) < 0) {
                return zone;
            } else {
                delete zone;
                // Continue searching or return NULL depending on if only latest is needed
                return NULL; // Found duplicate
            }
         }
      }

      // --- Check for Bearish FVG (Gap between prev_prev_low and current_high) ---
      // Condition: current_high < prev_prev_low
      if(current_high < prev_prev_low)
      {
         double fvg_high = prev_prev_low;
         double fvg_low = current_high;
         double fvg_size_points = (fvg_high - fvg_low) / symbolInfo.Point();

         // Check minimum size
         if(fvg_size_points >= InpMinFVGSizePoints)
         {
            // Found a Bearish FVG
            CPriceZone *zone = new CPriceZone();
            zone.zone_type = ZONE_TYPE_FVG_BEAR;
            zone.high = fvg_high;
            zone.low = fvg_low;
            // Anchor time is the middle candle's time (prev)
            zone.time_start = g_rates[i+1].time;
            zone.bar_index_anchor = i+1;
            zone.object_name = GenerateObjectName(zone.zone_type, zone.time_start);
            if(g_zones.Search(zone) < 0) {
                return zone;
            } else {
                delete zone;
                return NULL; // Found duplicate
            }
         }
      }
   }

   return NULL; // No FVG found within lookback
}


// Optimized function to find the last Liquidity Sweep (LS) before a given shift
// Returns a CStructurePoint object pointer if found, otherwise NULL
// Uses the global g_rates array
CStructurePoint* FindLiquiditySweepOptimized(const int start_shift)
{
   if(!InpDrawLiquiditySweeps) return NULL;
   int rates_count = ArraySize(g_rates);
   int swing_lookback = InpSwingLookback; // Use same lookback as structure for consistency
   int N = InpStructuralSwingMinBars;
   double min_spike_pips = InpSweepMinSpikePoints * symbolInfo.Point();

   // Iterate backwards from the bar *before* start_shift
   for(int i = start_shift + 1; i < MathMin(rates_count - N, start_shift + 1 + swing_lookback + N); i++)
   {
      // --- Check for Bearish Sweep (High Swept) ---
      // Find the most recent swing high *before* the potential sweep candle (i)
      SwingPointInfo prev_swing_high = GetLastSignificantSwingHighOptimized(swing_lookback, N, i); // Lookback before bar 'i'

      if(prev_swing_high.isValid)
      {
         // Potential sweep candle is at shift 'i'
         double current_high = g_rates[i].high;
         double current_low = g_rates[i].low;
         double current_close = g_rates[i].close;

         // Condition 1: Current high must exceed the previous swing high by the minimum spike amount
         if(current_high > prev_swing_high.price && (current_high - prev_swing_high.price) >= min_spike_pips)
         {
            // Condition 2: Price must close back below the swept high within N candles
            bool closed_back = false;
            for(int k = 0; k < InpSweepCloseBackCandles; k++)
            {
               int check_shift = i - k;
               if(check_shift < 0) break; // Don't go beyond current bar
               if(g_rates[check_shift].close < prev_swing_high.price)
               {
                  closed_back = true;
                  break;
               }
            }

            if(closed_back)
            {
               // Found a Bearish Sweep
               CStructurePoint *sp = new CStructurePoint();
               sp.is_sweep = true;
               sp.is_bullish_sweep = false;
               sp.price = prev_swing_high.price; // Price level swept
               sp.time = g_rates[i].time;       // Time of the sweep candle
               sp.bar_index = i;
               sp.object_name = GenerateObjectName(sp.is_bullish_sweep, sp.time);
               if(g_structure_points.Search(sp) < 0) {
                   return sp;
               } else {
                   delete sp;
                   return NULL; // Duplicate
               }
            }
         }
      }

      // --- Check for Bullish Sweep (Low Swept) ---
      // Find the most recent swing low *before* the potential sweep candle (i)
      SwingPointInfo prev_swing_low = GetLastSignificantSwingLowOptimized(swing_lookback, N, i);

      if(prev_swing_low.isValid)
      {
         double current_high = g_rates[i].high;
         double current_low = g_rates[i].low;
         double current_close = g_rates[i].close;

         // Condition 1: Current low must break below the previous swing low by the minimum spike amount
         if(current_low < prev_swing_low.price && (prev_swing_low.price - current_low) >= min_spike_pips)
         {
            // Condition 2: Price must close back above the swept low within N candles
            bool closed_back = false;
            for(int k = 0; k < InpSweepCloseBackCandles; k++)
            {
               int check_shift = i - k;
               if(check_shift < 0) break;
               if(g_rates[check_shift].close > prev_swing_low.price)
               {
                  closed_back = true;
                  break;
               }
            }

            if(closed_back)
            {
               // Found a Bullish Sweep
               CStructurePoint *sp = new CStructurePoint();
               sp.is_sweep = true;
               sp.is_bullish_sweep = true;
               sp.price = prev_swing_low.price; // Price level swept
               sp.time = g_rates[i].time;      // Time of the sweep candle
               sp.bar_index = i;
               sp.object_name = GenerateObjectName(sp.is_bullish_sweep, sp.time);
               if(g_structure_points.Search(sp) < 0) {
                   return sp;
               } else {
                   delete sp;
                   return NULL; // Duplicate
               }
            }
         }
      }
   }
   return NULL; // No sweep found
}

// Optimized function to find the last Structure Break (BOS/CHoCH) before a given shift
// Returns a CStructurePoint object pointer if found, otherwise NULL
// Uses the global g_rates array
CStructurePoint* FindStructureBreakOptimized(const int start_shift)
{
   if(!InpDrawStructure) return NULL;
   int rates_count = ArraySize(g_rates);
   int swing_lookback = InpSwingLookback;
   int N = InpStructuralSwingMinBars;

   // Iterate backwards from the bar *before* start_shift
   for(int i = start_shift + 1; i < MathMin(rates_count - N, start_shift + 1 + swing_lookback * 2 + N); i++) // Extend lookback slightly for structure
   {
      // --- Check for Bullish Structure Break (BOS High / CHoCH High) ---
      // Find the most recent significant swing high *before* the potential break candle (i)
      SwingPointInfo prev_swing_high = GetLastSignificantSwingHighOptimized(swing_lookback, N, i);

      if(prev_swing_high.isValid)
      {
         // Potential break candle is at shift 'i'
         double current_close = g_rates[i].close;
         double current_high = g_rates[i].high;

         // Condition 1: Current candle must close above the previous swing high
         if(current_close > prev_swing_high.price)
         {
            // Condition 2 (Optional): Check if a liquidity sweep occurred recently before this break
            bool sweep_occurred = !InpStructureRequiresSweep; // Assume true if not required
            if(InpStructureRequiresSweep)
            {
               // Look for a recent *bearish* sweep (sweeping a high) before the break candle 'i'
               // Search between the swing high bar and the break bar
               for(int sweep_check_shift = i + 1; sweep_check_shift <= prev_swing_high.bar_index + swing_lookback; sweep_check_shift++)
               {
                   CStructurePoint* recent_sweep = FindLiquiditySweepOptimized(sweep_check_shift);
                   if(recent_sweep != NULL && !recent_sweep.is_bullish_sweep && recent_sweep.bar_index < i && recent_sweep.bar_index >= prev_swing_high.bar_index)
                   {
                       sweep_occurred = true;
                       delete recent_sweep; // Clean up temporary object
                       break;
                   }
                   if(recent_sweep != NULL) delete recent_sweep;
               }
            }

            if(sweep_occurred)
            {
               // Determine if it's BOS or CHoCH
               // Find the swing low *before* the broken swing high
               SwingPointInfo low_before_high = GetLastSignificantSwingLowOptimized(swing_lookback, N, prev_swing_high.bar_index);
               ENUM_STRUCTURE_TYPE break_type = STRUCTURE_NONE;

               if(low_before_high.isValid)
               {
                  // Find the swing high *before* that swing low
                  SwingPointInfo high_before_low = GetLastSignificantSwingHighOptimized(swing_lookback, N, low_before_high.bar_index);
                  if(high_before_low.isValid && high_before_low.price < prev_swing_high.price) {
                      // If the previous high (high_before_low) was lower than the broken high (prev_swing_high),
                      // it suggests an uptrend continuation -> BOS Bullish
                      break_type = STRUCTURE_BOS_BULL;
                  } else {
                      // Otherwise, it could be a change of character from downtrend/ranging to uptrend -> CHoCH Bullish
                      break_type = STRUCTURE_CHoCH_BULL;
                  }
               } else {
                   // If no valid low found before the high, assume CHoCH as it's the first major high break
                   break_type = STRUCTURE_CHoCH_BULL;
               }

               // Found a Bullish Break
               CStructurePoint *sp = new CStructurePoint();
               sp.is_sweep = false;
               sp.structure_type = break_type;
               sp.price = prev_swing_high.price; // Price level broken
               sp.time = g_rates[i].time;       // Time of the break candle
               sp.bar_index = i;
               sp.object_name = GenerateObjectName(sp.structure_type, sp.time);
               if(g_structure_points.Search(sp) < 0) {
                   return sp;
               } else {
                   delete sp;
                   return NULL; // Duplicate
               }
            }
         }
      }

      // --- Check for Bearish Structure Break (BOS Low / CHoCH Low) ---
      // Find the most recent significant swing low *before* the potential break candle (i)
      SwingPointInfo prev_swing_low = GetLastSignificantSwingLowOptimized(swing_lookback, N, i);

      if(prev_swing_low.isValid)
      {
         double current_close = g_rates[i].close;
         double current_low = g_rates[i].low;

         // Condition 1: Current candle must close below the previous swing low
         if(current_close < prev_swing_low.price)
         {
            // Condition 2 (Optional): Check if a liquidity sweep occurred recently before this break
            bool sweep_occurred = !InpStructureRequiresSweep;
            if(InpStructureRequiresSweep)
            {
               // Look for a recent *bullish* sweep (sweeping a low) before the break candle 'i'
               for(int sweep_check_shift = i + 1; sweep_check_shift <= prev_swing_low.bar_index + swing_lookback; sweep_check_shift++)
               {
                   CStructurePoint* recent_sweep = FindLiquiditySweepOptimized(sweep_check_shift);
                   if(recent_sweep != NULL && recent_sweep.is_bullish_sweep && recent_sweep.bar_index < i && recent_sweep.bar_index >= prev_swing_low.bar_index)
                   {
                       sweep_occurred = true;
                       delete recent_sweep;
                       break;
                   }
                   if(recent_sweep != NULL) delete recent_sweep;
               }
            }

            if(sweep_occurred)
            {
               // Determine if it's BOS or CHoCH
               // Find the swing high *before* the broken swing low
               SwingPointInfo high_before_low = GetLastSignificantSwingHighOptimized(swing_lookback, N, prev_swing_low.bar_index);
               ENUM_STRUCTURE_TYPE break_type = STRUCTURE_NONE;

               if(high_before_low.isValid)
               {
                  // Find the swing low *before* that swing high
                  SwingPointInfo low_before_high = GetLastSignificantSwingLowOptimized(swing_lookback, N, high_before_low.bar_index);
                  if(low_before_high.isValid && low_before_high.price > prev_swing_low.price) {
                      // If the previous low (low_before_high) was higher than the broken low (prev_swing_low),
                      // it suggests a downtrend continuation -> BOS Bearish
                      break_type = STRUCTURE_BOS_BEAR;
                  } else {
                      // Otherwise, it could be a change of character from uptrend/ranging to downtrend -> CHoCH Bearish
                      break_type = STRUCTURE_CHoCH_BEAR;
                  }
               } else {
                   // If no valid high found before the low, assume CHoCH
                   break_type = STRUCTURE_CHoCH_BEAR;
               }

               // Found a Bearish Break
               CStructurePoint *sp = new CStructurePoint();
               sp.is_sweep = false;
               sp.structure_type = break_type;
               sp.price = prev_swing_low.price; // Price level broken
               sp.time = g_rates[i].time;      // Time of the break candle
               sp.bar_index = i;
               sp.object_name = GenerateObjectName(sp.structure_type, sp.time);
               if(g_structure_points.Search(sp) < 0) {
                   return sp;
               } else {
                   delete sp;
                   return NULL; // Duplicate
               }
            }
         }
      }
   }
   return NULL; // No structure break found
}

//--- Dashboard Functions ---

// Helper to create or update a dashboard text label
void CreateOrUpdateDashboardLabel(string name, string text, int line_num, color text_color)
{
   string obj_name = g_object_prefix + "Dashboard_" + name;
   int x_pos = InpDashboardXOffset;
   int y_pos = InpDashboardYOffset + (line_num * (InpDashboardFontSize + 4)); // Adjust spacing based on font size

   if(ObjectFind(g_chart_id, obj_name) < 0)
   {
      if(!ObjectCreate(g_chart_id, obj_name, OBJ_LABEL, 0, 0, 0))
      {
         PrintFormat("Error creating dashboard label %s: %d", obj_name, GetLastError());
         return;
      }
      // Set constant properties for new label
      ObjectSetInteger(g_chart_id, obj_name, OBJPROP_CORNER, InpDashboardCorner);
      ObjectSetInteger(g_chart_id, obj_name, OBJPROP_XDISTANCE, x_pos);
      ObjectSetInteger(g_chart_id, obj_name, OBJPROP_YDISTANCE, y_pos);
      ObjectSetInteger(g_chart_id, obj_name, OBJPROP_FONTSIZE, InpDashboardFontSize);
      ObjectSetString(g_chart_id, obj_name, OBJPROP_FONT, "Courier New"); // Use monospace for alignment
      ObjectSetInteger(g_chart_id, obj_name, OBJPROP_COLOR, text_color);
      ObjectSetInteger(g_chart_id, obj_name, OBJPROP_BACK, false);
      ObjectSetInteger(g_chart_id, obj_name, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(g_chart_id, obj_name, OBJPROP_ZORDER, 10); // Keep dashboard on top
   }
   // Update dynamic properties
   ObjectSetString(g_chart_id, obj_name, OBJPROP_TEXT, text);
   // Update position in case settings changed (though unlikely without reinit)
   ObjectSetInteger(g_chart_id, obj_name, OBJPROP_XDISTANCE, x_pos);
   ObjectSetInteger(g_chart_id, obj_name, OBJPROP_YDISTANCE, y_pos);
   ObjectSetInteger(g_chart_id, obj_name, OBJPROP_COLOR, text_color); // Update color if needed
}

// Function to update the on-screen dashboard content
void UpdateDashboard()
{
   if(!InpShowDashboard) {
       // If dashboard is turned off, delete existing labels
       DeleteObjectsByPrefix(g_object_prefix + "Dashboard_");
       return;
   }

   // Throttle updates
   if(TimeCurrent() - g_last_dashboard_update < InpDashboardUpdateFreqSecs) return;
   g_last_dashboard_update = TimeCurrent();

   int line = 0;
   string text;

   // --- Title ---
   text = "SMC Visualizer v" + (string)__MQL5__.version;
   CreateOrUpdateDashboardLabel("Title", text, line++, InpDashboardTextColor);

   // --- Separator ---
   text = "--------------------";
   CreateOrUpdateDashboardLabel("Sep1", text, line++, InpDashboardTextColor);

   // --- Last Zones --- 
   CPriceZone *last_bull_ob = NULL, *last_bear_ob = NULL;
   CPriceZone *last_bull_fvg = NULL, *last_bear_fvg = NULL;

   // Find the most recent of each type (iterate backwards)
   for(int i = g_zones.Total() - 1; i >= 0; i--)
   {
      CPriceZone *zone = g_zones.At(i);
      if(zone == NULL) continue;
      if(zone.status == ZONE_STATUS_MITIGATED_FULL) continue; // Skip fully mitigated

      if(zone.zone_type == ZONE_TYPE_OB_BULL && last_bull_ob == NULL) last_bull_ob = zone;
      if(zone.zone_type == ZONE_TYPE_OB_BEAR && last_bear_ob == NULL) last_bear_ob = zone;
      if(zone.zone_type == ZONE_TYPE_FVG_BULL && last_bull_fvg == NULL) last_bull_fvg = zone;
      if(zone.zone_type == ZONE_TYPE_FVG_BEAR && last_bear_fvg == NULL) last_bear_fvg = zone;

      if(last_bull_ob != NULL && last_bear_ob != NULL && last_bull_fvg != NULL && last_bear_fvg != NULL) break; // Found all needed
   }

   text = "Last Zones (Unmitigated/Partial):";
   CreateOrUpdateDashboardLabel("ZoneTitle", text, line++, InpDashboardTextColor);

   text = StringFormat(" Bull OB: %s", last_bull_ob != NULL ? DoubleToString(last_bull_ob->low, _Digits) : "--");
   CreateOrUpdateDashboardLabel("BullOB", text, line++, InpBullishOBColor);

  text = StringFormat(" Bear OB: %s", last_bear_ob != NULL ? DoubleToString(last_bear_ob->high, _Digits) : "--");
   CreateOrUpdateDashboardLabel("BearOB", text, line++, InpBearishOBColor);

  text = StringFormat(" Bull FVG: %s", last_bull_fvg != NULL ? DoubleToString(last_bull_fvg->low, _Digits) : "--");
   CreateOrUpdateDashboardLabel("BullFVG", text, line++, InpBullishFVGColor);

 text = StringFormat(" Bear FVG: %s", last_bear_fvg != NULL ? DoubleToString(last_bear_fvg->high, _Digits) : "--");
   CreateOrUpdateDashboardLabel("BearFVG", text, line++, InpBearishFVGColor);

   // --- Separator ---
   text = "--------------------";
   CreateOrUpdateDashboardLabel("Sep2", text, line++, InpDashboardTextColor);

   // --- Last Structure --- 
   CStructurePoint *last_bos = NULL, *last_choch = NULL, *last_ls = NULL;

   for(int i = g_structure_points.Total() - 1; i >= 0; i--)
   {
      CStructurePoint *sp = g_structure_points.At(i);
      if(sp == NULL) continue;

      if(sp.is_sweep && last_ls == NULL) last_ls = sp;
      if((sp.structure_type == STRUCTURE_BOS_BULL || sp.structure_type == STRUCTURE_BOS_BEAR) && last_bos == NULL) last_bos = sp;
      if((sp.structure_type == STRUCTURE_CHoCH_BULL || sp.structure_type == STRUCTURE_CHoCH_BEAR) && last_choch == NULL) last_choch = sp;

      if(last_bos != NULL && last_choch != NULL && last_ls != NULL) break;
   }

   text = "Last Structure/Sweep:";
   CreateOrUpdateDashboardLabel("StructTitle", text, line++, InpDashboardTextColor);

   string bos_str = "--";
   color bos_color = InpDashboardTextColor;
   if(last_bos != NULL) {
       bos_str = StringFormat("%s @ %s", (last_bos.structure_type == STRUCTURE_BOS_BULL ? "Bull" : "Bear"), DoubleToString(last_bos.price, _Digits));
       bos_color = InpBOSColor;
   }
   text = StringFormat(" BOS: %s", bos_str);
   CreateOrUpdateDashboardLabel("LastBOS", text, line++, bos_color);

   string choch_str = "--";
   color choch_color = InpDashboardTextColor;
   if(last_choch != NULL) {
       choch_str = StringFormat("%s @ %s", (last_choch.structure_type == STRUCTURE_CHoCH_BULL ? "Bull" : "Bear"), DoubleToString(last_choch.price, _Digits));
       choch_color = InpCHoCHColor;
   }
   text = StringFormat(" CHoCH: %s", choch_str);
   CreateOrUpdateDashboardLabel("LastCHoCH", text, line++, choch_color);

   string ls_str = "--";
   color ls_color = InpDashboardTextColor;
   if(last_ls != NULL) {
       ls_str = StringFormat("%s @ %s", (last_ls.is_bullish_sweep ? "Bull" : "Bear"), DoubleToString(last_ls.price, _Digits));
       ls_color = last_ls.is_bullish_sweep ? InpBullishLSColor : InpBearishLSColor;
   }
   text = StringFormat(" Sweep: %s", ls_str);
   CreateOrUpdateDashboardLabel("LastLS", text, line++, ls_color);

   // --- Settings Status ---
   // (Optional: Add lines to show if major features are enabled)
   // text = StringFormat("OB:%s FVG:%s LS:%s STR:%s ALR:%s",
   //                     InpDrawOrderBlocks?"On":"Off", InpDrawFairValueGaps?"On":"Off",
   //                     InpDrawLiquiditySweeps?"On":"Off", InpDrawStructure?"On":"Off",
   //                     InpEnableAlerts?"On":"Off");
   // CreateOrUpdateDashboardLabel("Settings", text, line++, clrGray);

}


//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
{
   // Initialization
   g_chart_id = ChartID();
   if(!symbolInfo.Name(_Symbol)) return(INIT_FAILED);
   g_object_prefix = InpObjectPrefix + StringSubstr(IntegerToString(g_chart_id), 0, 4) + "_"; // Make prefix chart specific

   // Set short name
   indicator_short_name = "SMC Visualizer v2.0";
   IndicatorSetString(INDICATOR_SHORTNAME, indicator_short_name);

   // Set properties for drawing objects (though we manage them directly)
   IndicatorSetInteger(INDICATOR_DIGITS, _Digits);

   // Initialize arrays
   g_zones.Clear();
   g_zones.Sort(); // Keep sorted for potentially faster searching
   g_structure_points.Clear();
   g_structure_points.Sort();

   // Initial calculation to draw historical data
   // Copy initial rates needed
   int bars_to_copy = Bars(_Symbol, _Period);
   if(InpMaxBarsToCalculate > 0) bars_to_copy = MathMin(bars_to_copy, InpMaxBarsToCalculate);
   if(CopyRates(_Symbol, _Period, 0, bars_to_copy, g_rates) <= 0)
   {
      Print("Error copying rates in OnInit!");
      return(INIT_FAILED);
   }
   ArraySetAsSeries(g_rates, true); // Ensure g_rates is treated as series

   // Perform initial full calculation
   OnCalculate(rates_total, 0, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL); // Call with dummy values to trigger full recalc

   PrintFormat("%s initialized successfully on %s, %s. Analyzing %d bars.",
               indicator_short_name, _Symbol, EnumToString(_Period), ArraySize(g_rates));
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   // Cleanup
   DeleteAllIndicatorObjects();
   // Delete dashboard labels specifically if they weren't caught by prefix
   DeleteObjectsByPrefix(g_object_prefix + "Dashboard_");

   // Free memory used by arrays
   g_zones.Shutdown();
   g_structure_points.Shutdown();

   PrintFormat("%s deinitialized. Reason: %d", indicator_short_name, reason);
}

//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,        // size of price[] array
                const int prev_calculated,    // bars calculated at previous call
                const datetime &time[],       // Time array
                const double &open[],         // Open array
                const double &high[],         // High array
                const double &low[],          // Low array
                const double &close[],        // Close array
                const long &tick_volume[],    // Tick Volume array
                const long &volume[],         // Real Volume array
                const int &spread[])          // Spread array
{
   // --- 1. Update Rates Data --- 
   int bars_to_copy = rates_total;
   if(InpMaxBarsToCalculate > 0) bars_to_copy = MathMin(rates_total, InpMaxBarsToCalculate);
   if(CopyRates(_Symbol, _Period, 0, bars_to_copy, g_rates) <= 0)
   {
      Print("Error copying rates in OnCalculate!");
      return(prev_calculated); // Return previous count on error
   }
   ArraySetAsSeries(g_rates, true);
   int current_rates_count = ArraySize(g_rates);
   if(current_rates_count == 0) return(prev_calculated);

   // --- 2. Determine Calculation Range --- 
   // Calculate only necessary bars: from the first uncalculated bar up to the current bar (index 0)
   // Or recalculate more if needed (e.g., settings change, history update)
   int start_bar_shift;
   if(prev_calculated <= 0 || prev_calculated >= rates_total || rates_total != Bars(_Symbol, _Period)) {
       // Full recalculation needed (e.g., first run, history update, major change)
       start_bar_shift = current_rates_count - 1; // Start from the oldest available bar in g_rates
       DeleteAllIndicatorObjects(); // Clear existing objects for full recalc
       PrintFormat("Full recalculation triggered. Analyzing %d bars.", current_rates_count);
   } else {
       // Incremental calculation: Start from the newest bar not calculated last time
       // rates_total - prev_calculated gives the shift of the first bar needing calculation
       // Add a buffer (e.g., lookback periods) to ensure context is captured
       int buffer = MathMax(InpOrderBlockLookbackPeriod, MathMax(InpFVGLookbackPeriod, InpSwingLookback)) + InpStructuralSwingMinBars + 5;
       start_bar_shift = MathMin(current_rates_count - 1, rates_total - prev_calculated + buffer);
   }
   start_bar_shift = MathMax(0, start_bar_shift); // Ensure start_shift is not negative

   // Reset alert counts for the current (potentially new) bar
   ResetAlertCountsIfNeeded(g_rates[0].time);

   // --- 3. Main Calculation Loop (Iterate from older bars to newer) --- 
   for(int shift = start_bar_shift; shift >= 0; shift--)
   {
      // --- 3a. Check Mitigation for Existing Zones --- 
      for(int j = 0; j < g_zones.Total(); j++)
      {
         CPriceZone *zone = g_zones.At(j);
         if(zone != NULL && zone.status != ZONE_STATUS_MITIGATED_FULL)
         {
            // Check mitigation only with bars *newer* than the zone's anchor bar
            if(shift < zone.bar_index_anchor)
            {
               CheckZoneMitigation(zone, shift);
               // Note: Drawing update happens later
            }
         }
      }

      // --- 3b. Find New Zones/Structures --- 
      // Look for patterns ending *before* the current 'shift'
      // We pass 'shift' as the 'start_shift' parameter to the find functions

      // Find Order Blocks
      if(InpDrawOrderBlocks)
      {
         CPriceZone *new_ob = FindOrderBlockOptimized(shift);
         if(new_ob != NULL)
         {
            if(g_zones.Add(new_ob)) // Add returns true if successful
            {
               // Alert for new unmitigated OB
               if(InpEnableAlerts && InpAlertOnOB && !IsAlertLimitReached("OB"))
               {
                  string alert_msg = StringFormat("New %s OB detected @ %s (Bar: %s)",
                                                (new_ob.zone_type == ZONE_TYPE_OB_BULL ? "Bullish" : "Bearish"),
                                                DoubleToString(new_ob.zone_type == ZONE_TYPE_OB_BULL ? new_ob.low : new_ob.high, _Digits),
                                                TimeToString(new_ob.time_start, TIME_DATE|TIME_MINUTES));
                  SendAlert(alert_msg, (ENUM_ALERT_TYPE)InpAlertType);
                  IncrementAlertCount("OB");
               }
            }
            else
            {
               delete new_ob; // Failed to add (e.g., duplicate), delete the object
            }
         }
      }

      // Find Fair Value Gaps
      if(InpDrawFairValueGaps)
      {
         CPriceZone *new_fvg = FindFairValueGapOptimized(shift);
         if(new_fvg != NULL)
         {
            if(g_zones.Add(new_fvg))
            {
               // Alert for new unmitigated FVG
               if(InpEnableAlerts && InpAlertOnFVG && !IsAlertLimitReached("FVG"))
               {
                  string alert_msg = StringFormat("New %s FVG detected [%s - %s] (Bar: %s)",
                                                (new_fvg.zone_type == ZONE_TYPE_FVG_BULL ? "Bullish" : "Bearish"),
                                                DoubleToString(new_fvg.low, _Digits),
                                                DoubleToString(new_fvg.high, _Digits),
                                                TimeToString(new_fvg.time_start, TIME_DATE|TIME_MINUTES));
                  SendAlert(alert_msg, (ENUM_ALERT_TYPE)InpAlertType);
                  IncrementAlertCount("FVG");
               }
            }
            else
            {
               delete new_fvg;
            }
         }
      }

      // Find Liquidity Sweeps
      if(InpDrawLiquiditySweeps)
      {
         CStructurePoint *new_ls = FindLiquiditySweepOptimized(shift);
         if(new_ls != NULL)
         {
            if(g_structure_points.Add(new_ls))
            {
               // Alert for new LS
               if(InpEnableAlerts && InpAlertOnLS && !IsAlertLimitReached("LS"))
               {
                  string alert_msg = StringFormat("New %s Liquidity Sweep detected @ %s (Bar: %s)",
                                                (new_ls.is_bullish_sweep ? "Bullish" : "Bearish"),
                                                DoubleToString(new_ls.price, _Digits),
                                                TimeToString(new_ls.time, TIME_DATE|TIME_MINUTES));
                  SendAlert(alert_msg, (ENUM_ALERT_TYPE)InpAlertType);
                  IncrementAlertCount("LS");
               }
            }
            else
            {
               delete new_ls;
            }
         }
      }

      // Find Structure Breaks
      if(InpDrawStructure)
      {
         CStructurePoint *new_structure = FindStructureBreakOptimized(shift);
         if(new_structure != NULL)
         {
            if(g_structure_points.Add(new_structure))
            {
               // Alert for new Structure Break
               if(InpEnableAlerts && InpAlertOnStructure && !IsAlertLimitReached("Structure"))
               {
                  string type_str = "";
                  if(new_structure.structure_type == STRUCTURE_BOS_BULL) type_str = "Bullish BOS";
                  else if(new_structure.structure_type == STRUCTURE_BOS_BEAR) type_str = "Bearish BOS";
                  else if(new_structure.structure_type == STRUCTURE_CHoCH_BULL) type_str = "Bullish CHoCH";
                  else if(new_structure.structure_type == STRUCTURE_CHoCH_BEAR) type_str = "Bearish CHoCH";

                  string alert_msg = StringFormat("New %s detected @ %s (Bar: %s)",
                                                type_str,
                                                DoubleToString(new_structure.price, _Digits),
                                                TimeToString(new_structure.time, TIME_DATE|TIME_MINUTES));
                  SendAlert(alert_msg, (ENUM_ALERT_TYPE)InpAlertType);
                  IncrementAlertCount("Structure");
               }
            }
            else
            {
               delete new_structure;
            }
         }
      }

   } // End of main calculation loop (for shift)

   // --- 4. Update Drawings --- 
   // Iterate through all managed zones and structure points and draw/update them
   for(int i = 0; i < g_zones.Total(); i++)
   {
      DrawZoneObject(g_zones.At(i));
   }
   for(int i = 0; i < g_structure_points.Total(); i++)
   {
      DrawStructurePointObject(g_structure_points.At(i));
   }

   // --- 5. Cleanup Old Objects --- 
   CleanupOldObjects(InpDeleteObjectsOlderThanNBars);

   // --- 6. Update Dashboard --- 
   UpdateDashboard();

   // --- 7. Redraw Chart --- 
   ChartRedraw(g_chart_id);

   // Return value of prev_calculated for next call
   return(rates_total);
}
//+------------------------------------------------------------------+
//| End of Indicator Code                                            |
//+------------------------------------------------------------------+











