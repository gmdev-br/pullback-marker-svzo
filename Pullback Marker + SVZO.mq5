//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "© GM, 2023"
#property description "Pullback marker + SVZO"
#property indicator_chart_window
#property indicator_buffers 0
#property indicator_plots   0

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
enum ENUM_REG_SOURCE {
   Open,           // Open
   High,           // High
   Low,             // Low
   Close,         // Close
   Typical,     // Typical
};

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
input int                              inpPeriod                   = 10;    // Period
input ENUM_REG_SOURCE                  inputSource = Close;
input bool                             shortMode = false;
input int                              input_start = 0;
input int                              input_end = 0;
input string                           inputAtivo                 = "";
input bool                             segundo_ativo              = false;
input string                           inputAtivo2                = "";
input ENUM_TIMEFRAMES                  timeframe                  = PERIOD_D1;
input bool                             enable5                    = false;
input bool                             enable15                   = false;
input bool                             enable30                   = false;
input bool                             enable60                   = false;
input bool                             enable4h                   = true;
input bool                             enableD                    = true;
input bool                             enableW                    = true;
input ENUM_APPLIED_VOLUME              applied_volume             = VOLUME_REAL;          // Volume type
input int                              useLastCandlesLP           = 100; // Bars back for long timeframes
input int                              useLastCandlesCP           = 100; // Bars back for short timeframes
input double                           InpExtremeOverbought       = 80.0; // Extreme overbought
input double                           InpHighOverbought          = 60.0; // High overbought
input double                           InpOverbought              = 40.0; // Overbought
input double                           InpOversold                = -40.0; // Oversold
input double                           InpHighOversold            = -60.0; // High oversold
input double                           InpExtremeOversold         = -80.0; // Extreme oversold
input int                              inpSignalPeriod            = 20;
input datetime                         DefaultInitialDate         = "2021.1.1 09:00:00";          // Data inicial padrão
input int                              WaitMilliseconds           = 1500;  // Timer (milliseconds) for recalculation

input bool                             useFirstLine               = true;
input int                              larguraResLP               = 1;
input color                            corResLP                   = clrRed;
input ENUM_LINE_STYLE                  estiloResLP                = STYLE_DOT;
input int                              larguraSupLP               = 1;
input color                            corSupLP                   = clrLime;
input ENUM_LINE_STYLE                  estiloSupLP                = STYLE_DOT;

input int                              larguraResCP               = 1;
input color                            corResCP                   = clrDarkOrange;
input ENUM_LINE_STYLE                  estiloResCP                = STYLE_DOT;
input int                              larguraSupCP               = 1;
input color                            corSupCP                   = clrDodgerBlue;
input ENUM_LINE_STYLE                  estiloSupCP                = STYLE_DOT;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double vzo_high[], vzo_low[];
long arrayVolume[];
double regChannelBuffer[];
double upChannel1[], upChannel2[];
double downChannel1[], downChannel2[];
double A, B, stdev_low, stdev_high;
datetime data_inicial;
int barFrom;
string ativo, ativo2;
datetime       arrayTime[];
double         arrayOpen[], arrayHigh[], arrayLow[], arrayClose[];
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit() {

   ArrayInitialize(regChannelBuffer, 0);
   ArrayInitialize(upChannel1, 0);
   ArrayInitialize(downChannel1, 0);
   ArrayInitialize(upChannel2, 0);
   ArrayInitialize(downChannel2, 0);

   ArraySetAsSeries(regChannelBuffer, true);
   ArraySetAsSeries(upChannel1, true);
   ArraySetAsSeries(downChannel1, true);
   ArraySetAsSeries(upChannel2, true);
   ArraySetAsSeries(downChannel2, true);

   IndicatorSetInteger(INDICATOR_DIGITS, 1);

   data_inicial = DefaultInitialDate;
   barFrom = iBarShift(ativo, timeframe, data_inicial);
   ativo = inputAtivo;
   StringToUpper(ativo);
   if (ativo == "")
      ativo = _Symbol;

   if (segundo_ativo && inputAtivo2 != "") {
      ativo2 = inputAtivo2;
      StringToUpper(ativo2);
   }

   _updateTimer = new MillisecondTimer(WaitMilliseconds, false);
   EventSetMillisecondTimer(WaitMilliseconds);

   ObjectsDeleteAll(0, "VZO_");

//   ObjectsDeleteAll(0, "VZO_" + ativo + "_" + GetTimeFrame(PERIOD_MN1) + "_sup_" );
//   ObjectsDeleteAll(0, "VZO_" + ativo + "_" + GetTimeFrame(PERIOD_MN1) + "_res_" );
//
//   ObjectsDeleteAll(0, "VZO_" + ativo + "_" + GetTimeFrame(PERIOD_W1) + "_sup_" );
//   ObjectsDeleteAll(0, "VZO_" + ativo + "_" + GetTimeFrame(PERIOD_W1) + "_res_" );
//
//   ObjectsDeleteAll(0, "VZO_" + ativo + "_" + GetTimeFrame(PERIOD_D1) + "_sup_" );
//   ObjectsDeleteAll(0, "VZO_" + ativo + "_" + GetTimeFrame(PERIOD_D1) + "_res_" );
//
//   ObjectsDeleteAll(0, "VZO_" + ativo + "_" + GetTimeFrame(PERIOD_H1) + "_sup_" );
//   ObjectsDeleteAll(0, "VZO_" + ativo + "_" + GetTimeFrame(PERIOD_H1) + "_res_" );
//
//   ObjectsDeleteAll(0, "VZO_" + ativo + "_" + GetTimeFrame(PERIOD_M30) + "_sup_" );
//   ObjectsDeleteAll(0, "VZO_" + ativo + "_" + GetTimeFrame(PERIOD_M30) + "_res_" );
//
//   ObjectsDeleteAll(0, "VZO_" + ativo + "_" + GetTimeFrame(PERIOD_M15) + "_sup_" );
//   ObjectsDeleteAll(0, "VZO_" + ativo + "_" + GetTimeFrame(PERIOD_M15) + "_res_" );
//
//   ObjectsDeleteAll(0, "VZO_" + ativo + "_" + GetTimeFrame(PERIOD_M5) + "_sup_" );
//   ObjectsDeleteAll(0, "VZO_" + ativo + "_" + GetTimeFrame(PERIOD_M5) + "_res_" );

   ChartRedraw();

   IndicatorSetString(INDICATOR_SHORTNAME, "SF SVZO");

   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {

   delete(_updateTimer);

   ObjectsDeleteAll(0, "VZO_" + ativo + "_" + GetTimeFrame(timeframe) + "_sup_" );
   ObjectsDeleteAll(0, "VZO_" + ativo + "_" + GetTimeFrame(timeframe) + "_res_" );
   ObjectsDeleteAll(0, "VZO_" + ativo2 + "_" + GetTimeFrame(timeframe) + "_sup_" );
   ObjectsDeleteAll(0, "VZO_" + ativo2 + "_" + GetTimeFrame(timeframe) + "_res_" );

   if(reason == REASON_REMOVE) {
      ObjectsDeleteAll(0, "VZO_");
//      ObjectsDeleteAll(0, "VZO_" + ativo + "_" + GetTimeFrame(PERIOD_MN1) + "_sup_" );
//      ObjectsDeleteAll(0, "VZO_" + ativo + "_" + GetTimeFrame(PERIOD_MN1) + "_res_" );
//
//      ObjectsDeleteAll(0, "VZO_" + ativo + "_" + GetTimeFrame(PERIOD_W1) + "_sup_" );
//      ObjectsDeleteAll(0, "VZO_" + ativo + "_" + GetTimeFrame(PERIOD_W1) + "_res_" );
//
//      ObjectsDeleteAll(0, "VZO_" + ativo + "_" + GetTimeFrame(PERIOD_D1) + "_sup_" );
//      ObjectsDeleteAll(0, "VZO_" + ativo + "_" + GetTimeFrame(PERIOD_D1) + "_res_" );
//
//      ObjectsDeleteAll(0, "VZO_" + ativo + "_" + GetTimeFrame(PERIOD_H1) + "_sup_" );
//      ObjectsDeleteAll(0, "VZO_" + ativo + "_" + GetTimeFrame(PERIOD_H1) + "_res_" );
//
//      ObjectsDeleteAll(0, "VZO_" + ativo + "_" + GetTimeFrame(PERIOD_M30) + "_sup_" );
//      ObjectsDeleteAll(0, "VZO_" + ativo + "_" + GetTimeFrame(PERIOD_M30) + "_res_" );
//
//      ObjectsDeleteAll(0, "VZO_" + ativo + "_" + GetTimeFrame(PERIOD_M15) + "_sup_" );
//      ObjectsDeleteAll(0, "VZO_" + ativo + "_" + GetTimeFrame(PERIOD_M15) + "_res_" );
//
//      ObjectsDeleteAll(0, "VZO_" + ativo + "_" + GetTimeFrame(PERIOD_M5) + "_sup_" );
//      ObjectsDeleteAll(0, "VZO_" + ativo + "_" + GetTimeFrame(PERIOD_M5) + "_res_" );
   }

   ChartRedraw();

}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double work[][2];
#define _vp 0
#define _tv 1
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool Update(string p_ativo, ENUM_TIMEFRAMES tf, long p_last_candles, color p_cor_sup, color p_cor_res) {

   int totalRates = SeriesInfoInteger(p_ativo, tf, SERIES_BARS_COUNT);
   int largura;
   ENUM_LINE_STYLE estilo;

   if (tf == PERIOD_W1) {
      largura = 5;
      estilo = STYLE_DASH;
   } else if (tf == PERIOD_D1)  {
      largura = 3;
      estilo = STYLE_DASH;
   } else if (tf == PERIOD_H4) {
      largura = 3;
      estilo = STYLE_DASH;
   } else if (tf == PERIOD_H1) {
      largura = 2;
      estilo = STYLE_DASH;
   } else if (tf == PERIOD_M30) {
      largura = 2;
      estilo = STYLE_DASH;
   } else if (tf == PERIOD_M15) {
      largura = 2;
      estilo = STYLE_DASH;
   } else if (tf == PERIOD_M5) {
      largura = 1;
      estilo = STYLE_DASH;
   }

   int tempVar = CopyLow(p_ativo, tf, 0, totalRates, arrayLow);
   tempVar = CopyClose(p_ativo, tf, 0, totalRates, arrayClose);
   tempVar = CopyHigh(p_ativo, tf, 0, totalRates, arrayHigh);
   tempVar = CopyOpen(p_ativo, tf, 0, totalRates, arrayOpen);

   ArrayReverse(arrayLow);
   ArrayReverse(arrayClose);
   ArrayReverse(arrayHigh);
   ArrayReverse(arrayOpen);

   ArraySetAsSeries(arrayOpen, true);
   ArraySetAsSeries(arrayLow, true);
   ArraySetAsSeries(arrayClose, true);
   ArraySetAsSeries(arrayHigh, true);

   if (Bars(_Symbol, _Period) < totalRates)
      return false;

   if (ArrayRange(work, 0) != totalRates)
      ArrayResize(work, totalRates);

   if (applied_volume == VOLUME_REAL)
      CopyRealVolume(p_ativo, tf, 0, totalRates, arrayVolume);
   else
      CopyTickVolume(p_ativo, tf, 0, totalRates, arrayVolume);

   ArraySetAsSeries(arrayVolume, true);
   ArrayReverse(arrayVolume);
   
   ArrayResize(regChannelBuffer, totalRates);
   ArrayResize(upChannel1, totalRates);
   ArrayResize(upChannel2, totalRates);
   ArrayResize(downChannel1, totalRates);
   ArrayResize(downChannel2, totalRates);
   ArrayResize(vzo_high, totalRates);
   ArrayResize(vzo_low, totalRates);

   double alpha = 2.0 / (1.0 + inpPeriod);
   double arrayAlvo[];

   ArrayCopy(arrayAlvo, arrayHigh);
   ArraySetAsSeries(arrayAlvo, true);

   for (int i = 0; i < totalRates; i++) {
      double sign = (i > 0) ? (arrayAlvo[i] > arrayAlvo[i - 1]) ? 1 : (arrayAlvo[i] < arrayAlvo[i - 1]) ? -1 : 0 : 0;
      double R = sign * arrayVolume[i];
      work[i][_vp] = (i == 0) ? R                      : work[i - 1][_vp] + alpha * (R             - work[i - 1][_vp]);
      work[i][_tv] = (i == 0) ? (double)arrayVolume[i] : work[i - 1][_tv] + alpha * (arrayVolume[i] - work[i - 1][_tv]);
      vzo_high[i] = (work[i][_tv] != 0) ? 100.0 * work[i][_vp] / work[i][_tv] : 0;
      vzo_high[i] = vzo_high[i] < -10 ? vzo_high[i] : 0;
   }

   ArrayFree(arrayAlvo);
   ArrayCopy(arrayAlvo, arrayLow);
   ArraySetAsSeries(arrayAlvo, true);

   for (int i = 0; i < totalRates; i++) {
      double sign = (i > 0) ? (arrayAlvo[i] > arrayAlvo[i - 1]) ? 1 : (arrayAlvo[i] < arrayAlvo[i - 1]) ? -1 : 0 : 0;
      double R = sign * arrayVolume[i];
      work[i][_vp] = (i == 0) ? R                      : work[i - 1][_vp] + alpha * (R             - work[i - 1][_vp]);
      work[i][_tv] = (i == 0) ? (double)arrayVolume[i] : work[i - 1][_tv] + alpha * (arrayVolume[i] - work[i - 1][_tv]);
      vzo_low[i] = (work[i][_tv] != 0) ? 100.0 * work[i][_vp] / work[i][_tv] : 0;
      vzo_low[i] = vzo_low[i] > 10 ? vzo_low[i] : 0;
   }

   barFrom = iBarShift(p_ativo, tf, data_inicial);

   for(int n = 0; n < ArraySize(regChannelBuffer) - 1; n++) {
      regChannelBuffer[n] = 0.0;
      upChannel2[n] = 0.0;
      upChannel1[n] = 0.0;
      downChannel1[n] = 0.0;
      downChannel2[n] = 0.0;
   }

   double dataArray[];
   ArrayCopy(dataArray, vzo_high);
   ArrayReverse(dataArray);
   CalcAB(dataArray, 0, barFrom, A, B);
   stdev_high = GetStdDev(dataArray, 0, barFrom); //calculate standand deviation
   for (int i = 0; i < barFrom; i++) {
      regChannelBuffer[i] = (A * (i) + B);
      downChannel1[i] = (A * (i) + B) - 2 * stdev_high;
      downChannel2[i] = (A * (i) + B) - 3 * stdev_high;
   }

   ArrayCopy(dataArray, vzo_low);
   ArrayReverse(dataArray);
   CalcAB(dataArray, 0, barFrom, A, B);
   stdev_low = GetStdDev(dataArray, 0, barFrom); //calculate standand deviation
   for (int i = 0; i < barFrom; i++) {
      upChannel2[i] = (A * (i) + B) + 2 * stdev_low;
      upChannel1[i] = (A * (i) + B) + 3 * stdev_low;
   }

   ObjectsDeleteAll(0, "VZO_" + p_ativo + "_" + GetTimeFrame(tf) + "_sup_");
   ObjectsDeleteAll(0, "VZO_" + p_ativo + "_" + GetTimeFrame(tf) + "_res_");

   double temp1[], temp2[], temp3[], temp4[];
   double preco;
   int supCount = 0, resCount = 0;
   int anterior = 0;
   string name;
   datetime end_time, start_time;
   ArrayCopy(temp1, upChannel2);
   ArrayCopy(temp2, upChannel1);
   ArrayCopy(temp3, downChannel1);
   ArrayCopy(temp4, downChannel2);

   for (int i = 0; i < totalRates; i++) {
      datetime data = iTime(p_ativo, tf, totalRates - i - 1);
      if (i >= totalRates - p_last_candles) {
         if (temp1[i] != 0 && temp2[i] != 0 && temp3[i] != 0 && temp4[i] != 0) {
            if ((vzo_low[i] >= temp1[i] || (vzo_low[i] >= temp2[i] && vzo_low[i] >= 35))) {
               preco = iHigh(p_ativo, tf, totalRates - i - 1);
               if (i + 1 < totalRates) {
                  if (vzo_low[i + 1] <= vzo_low[i]) {
                     //if (!(tempVzo[i + 1] >= temp1[i + 1])) {
                     if (!(vzo_low[i + 1] >= temp1[i + 1] || (vzo_low[i + 1] >= temp2[i + 1] && vzo_low[i + 1] >= 35))) {
                        name = "VZO_" + p_ativo + "_" + GetTimeFrame(tf) + "_sup_" + i;
                        if (shortMode) {
                           start_time = iTime(_Symbol, PERIOD_CURRENT, 0) + PeriodSeconds() * input_start;
                           end_time = iTime(_Symbol, PERIOD_CURRENT, 0) + PeriodSeconds() * input_end;
                        } else {
                           start_time = data;
                           end_time = iTime(p_ativo, PERIOD_M1, 0);
                        }
                        ObjectCreate(0, name, OBJ_TREND, 0, start_time, preco, end_time, preco);
                        ObjectSetInteger(0, name, OBJPROP_COLOR, p_cor_res);
                        ObjectSetInteger(0, name, OBJPROP_WIDTH, largura);
                        ObjectSetInteger(0, name, OBJPROP_STYLE, estilo);
                     }
                  }
               }
               //} else if ((tempVzo[i] <= temp4[i])) {
            }

            if ((vzo_high[i] <= temp4[i]) || (vzo_high[i] <= temp3[i] && vzo_high[i] <= -35)) {
               preco = iLow(p_ativo, tf, totalRates - i - 1);
               if (i + 1 < totalRates) {
                  if (vzo_high[i + 1] >= vzo_high[i]) {
                     if (!(vzo_high[i + 1] <= temp4[i + 1]) || (vzo_high[i + 1] <= temp3[i + 1] && vzo_high[i + 1] <= -35)) {
                        name = "VZO_" + p_ativo + "_" + GetTimeFrame(tf) + "_res_" + i;
                        if (shortMode) {
                           start_time = iTime(_Symbol, PERIOD_CURRENT, 0) + PeriodSeconds() * input_start;
                           end_time = iTime(_Symbol, PERIOD_CURRENT, 0) + PeriodSeconds() * input_end;
                        } else {
                           start_time = data;
                           end_time = iTime(p_ativo, PERIOD_M1, 0);
                        }
                        ObjectCreate(0, name, OBJ_TREND, 0, start_time, preco, end_time, preco);
                        ObjectSetInteger(0, name, OBJPROP_COLOR, p_cor_sup);
                        ObjectSetInteger(0, name, OBJPROP_WIDTH, largura);
                        ObjectSetInteger(0, name, OBJPROP_STYLE, estilo);
                     }
                  }
               }
            }
         }
      }
   }

   ChartRedraw();

   return true;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total, const int prev_calculated, const int begin, const double &price[]) {
   return (1);
}

//+------------------------------------------------------------------+
//| ChartEvent function                                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam) {

   if(id == CHARTEVENT_CHART_CHANGE) {
      _lastOK = false;
      CheckTimer();
   }
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//Linear Regression Calculation for sample data: arr[]
//line equation  y = f(x)  = ax + b
void CalcAB(const double &arr[], int start, int end, double & a, double & b) {

   a = 0.0;
   b = 0.0;
   int size = MathAbs(start - end) + 1;
   if(size < 2)
      return;

   double sumxy = 0.0, sumx = 0.0, sumy = 0.0, sumx2 = 0.0;
   for(int i = start; i < end; i++) {
      sumxy += i * arr[i];
      sumy += arr[i];
      sumx += i;
      sumx2 += i * i;
   }

   double M = size * sumx2 - sumx * sumx;
   if(M == 0.0)
      return;

   a = (size * sumxy - sumx * sumy) / M;
   b = (sumy - a * sumx) / size;

}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double GetStdDev(const double & arr[], int start, int end) {
   int size = MathAbs(start - end) + 1;
   if(size < 2)
      return(0.0);

   double sum = 0.0;
   for(int i = start; i < end; i++) {
      sum = sum + arr[i];
   }

   sum = sum / size;

   double sum2 = 0.0;
   for(int i = start; i < end; i++) {
      sum2 = sum2 + (arr[i] - sum) * (arr[i] - sum);
   }

   sum2 = sum2 / (size - 1);
   sum2 = MathSqrt(sum2);

   return(sum2);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class MillisecondTimer {

 private:
   int               _milliseconds;
 private:
   uint              _lastTick;

 public:
   void              MillisecondTimer(const int milliseconds, const bool reset = true) {
      _milliseconds = milliseconds;

      if(reset)
         Reset();
      else
         _lastTick = 0;
   }

 public:
   bool              Check() {
      uint now = getCurrentTick();
      bool stop = now >= _lastTick + _milliseconds;

      if(stop)
         _lastTick = now;

      return(stop);
   }

 public:
   void              Reset() {
      _lastTick = getCurrentTick();
   }

 private:
   uint              getCurrentTick() const {
      return(GetTickCount());
   }

};

bool _lastOK = false;
MillisecondTimer *_updateTimer;

//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer() {
   CheckTimer();
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CheckTimer() {
   EventKillTimer();

   if(_updateTimer.Check() || !_lastOK) {
      if (enable5) {
         _lastOK = Update(_Symbol, PERIOD_M5, useLastCandlesCP, corSupCP, corResCP);
         if (segundo_ativo)
            _lastOK = Update(ativo2, PERIOD_M5, useLastCandlesCP, corSupCP, corResCP);
      }

      if (enable15) {
         _lastOK = Update(_Symbol, PERIOD_M15, useLastCandlesCP, corSupCP, corResCP);
         if (segundo_ativo)
            _lastOK = Update(ativo2, PERIOD_M15, useLastCandlesCP, corSupCP, corResCP);
      }

      if (enable30) {
         _lastOK = Update(_Symbol, PERIOD_M30, useLastCandlesCP, corSupCP, corResCP);
         if (segundo_ativo)
            _lastOK = Update(ativo2, PERIOD_M30, useLastCandlesCP, corSupCP, corResCP);
      }

      if (enable60) {
         _lastOK = Update(_Symbol, PERIOD_H1, useLastCandlesCP, corSupCP, corResCP);
         if (segundo_ativo)
            _lastOK = Update(ativo2, PERIOD_H1, useLastCandlesCP, corSupCP, corResCP);
      }

      if (enable4h) {
         _lastOK = Update(_Symbol, PERIOD_H4, useLastCandlesLP, corSupLP, corResLP);
         if (segundo_ativo)
            _lastOK = Update(ativo2, PERIOD_H4, useLastCandlesLP, corSupLP, corResLP);
      }

      if (enableD) {
         _lastOK = Update(_Symbol, PERIOD_D1, useLastCandlesLP, corSupLP, corResLP);
         if (segundo_ativo)
            _lastOK = Update(ativo2, PERIOD_D1, useLastCandlesLP, corSupLP, corResLP);
      }

      if (enableW) {
         _lastOK = Update(_Symbol, PERIOD_W1, useLastCandlesLP, corSupLP, corResLP);
         if (segundo_ativo)
            _lastOK = Update(ativo2, PERIOD_W1, useLastCandlesLP, corSupLP, corResLP);
         //Print("aaaaa");
      }
      EventSetMillisecondTimer(WaitMilliseconds);

      _updateTimer.Reset();
   } else {
      EventSetTimer(1);
   }
}

//+---------------------------------------------------------------------+
//| GetTimeFrame function - returns the textual timeframe               |
//+---------------------------------------------------------------------+
string GetTimeFrame(int lPeriod) {
   switch(lPeriod) {
   case PERIOD_M1:
      return("M1");
   case PERIOD_M2:
      return("M2");
   case PERIOD_M3:
      return("M3");
   case PERIOD_M4:
      return("M4");
   case PERIOD_M5:
      return("M5");
   case PERIOD_M6:
      return("M6");
   case PERIOD_M10:
      return("M10");
   case PERIOD_M12:
      return("M12");
   case PERIOD_M15:
      return("M15");
   case PERIOD_M20:
      return("M20");
   case PERIOD_M30:
      return("M30");
   case PERIOD_H1:
      return("H1");
   case PERIOD_H2:
      return("H2");
   case PERIOD_H3:
      return("H3");
   case PERIOD_H4:
      return("H4");
   case PERIOD_H6:
      return("H6");
   case PERIOD_H8:
      return("H8");
   case PERIOD_H12:
      return("H12");
   case PERIOD_D1:
      return("D1");
   case PERIOD_W1:
      return("W1");
   case PERIOD_MN1:
      return("MN1");
   }
   return IntegerToString(lPeriod);
}
//+------------------------------------------------------------------+
