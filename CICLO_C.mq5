//+------------------------------------------------------------------+
//|                                                Indicator Ciclo_C |
//|                                      Copyright 2020, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+
#property indicator_chart_window
//#property indicator_separate_window
#property indicator_buffers 2
#property indicator_plots   2
//--- plot Compra
#property indicator_label1  "Compra"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrGold
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1
//--- plot Venda
#property indicator_label2  "Venda"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrRed
#property indicator_style2  STYLE_SOLID
#property indicator_width2  1
//--- input parameters
input int      periodo = 20;
input double      sensibilidade = 1.5;
//--- indicator buffers
double         CompraBuffer[];
double         VendaBuffer[];
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0,CompraBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,VendaBuffer,INDICATOR_DATA);

   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);

//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+

int nbase = 100000;
double comprado = 0;
double vendido = 0;
bool LC = false;
bool LV = false;

double peso1 = 0.0;
double peso2 = 0.0;
double peso3 = 0.0;

double multiplica_TR = 0.0;
double Tr0 = 0.0;
double Tr01 = 0.0;
double Tr02 = 0.0;
double Tr03 = 0.0;
double Atr = 0.0;
double numerador = 0.0;
double denominador = 0.0;
int Tperiodo = 0;
double Tr = 0.0;
double Tr1 = 0.0;
double Tr2 = 0.0;
double Tr3 = 0.0;
int bar = 0;

//+------------------------------------------------------------------+
//|                                                                  |
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
                const int &spread[])
  {

   if(rates_total<=periodo)
      return(0);


   if(bar < rates_total)
     {
      for(int i = periodo + 2; i < rates_total && !IsStopped(); i++)
        {
         Tr1 = high[i] - low[i];
         Tr2 = close[i-1] - low[i];
         Tr3 = close[i-1] - high[i];

         Tr = 0;

         if(Tr1 > Tr2 && Tr1 > Tr3)
           {
            Tr = Tr1;
           }
         else
            if(Tr2 > Tr3)
              {
               Tr = Tr2;
              }
            else
              {
               Tr = Tr3;
              }


         Atr = 0;
         numerador = 0;
         denominador = 0;
         Tperiodo = periodo;

         for(int j = i - periodo; j < i ; j ++)
           {
            Tr01 = high[j] - low[j];
            Tr02 = close[j-1] - low[j];
            Tr03 = close[j-1] - high[j];

            Tr0 = 0;

            if(Tr01 > Tr02 && Tr01 > Tr03)
              {
               Tr0 = Tr01;
              }
            else
               if(Tr02 > Tr03)
                 {
                  Tr0 = Tr02;
                 }
               else
                 {
                  Tr0 = Tr03;
                 }

            numerador = numerador + (Tperiodo * Tr0);
            denominador = denominador + Tperiodo;
            Tperiodo = Tperiodo - 1;
           }

         Atr = numerador / denominador;

         multiplica_TR = (Atr - (((sensibilidade * Tr) + Tr) / periodo));

         //double peso = (close[i-1] + open[i-1] + high[i-1] + low[i-1]) / 4;
         peso1 = (high[i-1] + low[i-1] + close[i-1] + close[i-1]) / 4;
         peso2 = (high[i-2] + low[i-2] + close[i-2] + close[i-2]) / 4;
         peso3 = (high[i-3] + low[i-3] + close[i-3] + close[i-3]) / 4;

         if(close[i] < nbase)
           {
            comprado = low[i] - multiplica_TR;
            vendido = high[i] + multiplica_TR;
            nbase = 0;
           }


         if(peso1 < comprado && peso2 < comprado /*&& peso3 < comprado*/)
           {
            comprado = low[i-1] - (multiplica_TR * sensibilidade);
            vendido = peso1 + (multiplica_TR * sensibilidade);
            LC = false;
            LV = true;
           }
         if(peso1 > vendido && peso2 > vendido /*&& peso3 > vendido*/)
           {
            vendido = high[i-1] + (multiplica_TR * sensibilidade);
            comprado = peso1 - (multiplica_TR * sensibilidade);
            LV = false;
            LC = true;
           }

         if(LV == true)
           {
            //VendaBuffer[i] = vendido;
           }
         if(LC == true)
           {
            //CompraBuffer[i] = comprado;
           }

         VendaBuffer[i] = vendido;
         CompraBuffer[i] = comprado;

         bar = rates_total;
        }
     }

   return(rates_total);
  }

/*
double GetLWA(double high)
{
   double numerador = 0;
   double denominador = 0;
   int Tperiodo = periodo;

   for(int i = 1; i < periodo; i ++)
   {
      double Tr1 = high[i] - low[i];
      double Tr2 = close[i-1] - low[i];
      double Tr3 = close[i-1] - high[i];

      numerador += Tperiodo * TrueRange(Tr1, Tr2, Tr3);
      denominador += Tperiodo
      Tperiodo -= 1;
   }

   return numerador / denominador;
}
*/
/*
double Tr = 0;

double TrueRange(double Tr_1, double Tr_2, double Tr_3)
{
        if(Tr_1 > Tr_2 && Tr_1 > Tr_3)
        {
            Tr = Tr_1;
        }
        else if(Tr_2 > Tr_3)
        {
            Tr = Tr_2;
            
        }else
        {
            Tr = Tr_3;
        }


   return Tr;
}
*/
//+------------------------------------------------------------------+
